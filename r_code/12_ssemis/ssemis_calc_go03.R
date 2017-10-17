#' ssemis_calc_go03
#'
#' This function calculates sea salt emissions following 
#' Gong (2003) [doi: 10.1029/2003GB002079]
#'
#' @author Daniel Neumann
#' @version 4.0.1
#' @date 2015-Nov-06
#' 


#' load libraries and functions ----
library('compiler')
library('ncdf4')
source('ssemis_params.R')
source('ssemis_funs.R')


ssemis_calc_go03_ = function(date, grid, namespace, modeIntegration=1, surfzone=TRUE) {
  print(paste('Integrating day', date, 'using GO03 on grid', grid$name, 'with surfzone =', surfzone, 'and with mode integration', modeIntegration, sep = ' '))
  
  # define needed functions ----
  #' R is actually the dry diameter ...
  dFdR_GO03_ = function(R) {
    A = 4.7 * (1 + 30 * R)^(-0.017 * R^(-1.44))
    B = (0.433 - log10(R))/0.433
    outF = (scaleW_GO03 * tmpOPEN + tmpSURF) * 3.5755 * 10^5 * R^(-A) * (1 + 0.057 * R^3.45) * 10^(1.607 * exp(-B^2))
    return(outF)
  }
  dFdR_GO03 = cmpfun(dFdR_GO03_)
  
  # calculate second moments
  M2_GO03dry = cmpfun(function(r) { return(r^2 * dFdR_GO03(r)) })
  M2_GO03dry = cmpfun(function(r) { return((r * wetFac)^2 * dFdR_GO03(r)) })
  
  # calculate third moments
  M3_GO03dry = cmpfun(function(r) { return(r^3 * dFdR_GO03(r)) })
  M3_GO03wet = cmpfun(function(r) { return((r * wetFac)^3 * dFdR_GO03(r)) })
  
  
  # read in input variables ----
  # get OCEAN file data
  if(surfzone) oceanType = 'wSZwSL' else oceanType = 'nSZwSL'
  ncId = nc_open(namespace$OCEAN[[oceanType]]$path)
  valOPEN = ncvar_get(ncId, 'OPEN')
  valSURF = ncvar_get(ncId, 'SURF')
  nc_close(ncId)
  
  # get u10
  ncId = nc_open(namespace$MC2D$path)
  valU10 = ncvar_get(ncId, 'WSPD10')
  nc_close(ncId)
  
  # get RH
  valRH = get_relativehumidity_a(date, grid, namespace)
  
  #' radius scale factor depending on RH
  scaleRH = size_scale_rh(valRH)
  
  # get integrations boundaries
  #' The integration boundaries between J and K mode are in an array
  #' with RH dependent indices. Here we determine the indices. If we
  #' are not directly on one array element we interpolate linearly
  #' between the two relevant elements. Therefore we need iRHl and
  #' iRHr which are the left and right indices, respectively. iRHp
  #' is the ratio of the left element to use and (1-iRHp) the ratio
  #' of the right element.
  tmpBack = calc_rh_index(valRH)
  iRHl = tmpBack$index
  iRHp = tmpBack$ratio
  iRHr = iRHl + (iRHl < 136)*(iRHp < 1.0)
  
  #' get DRY integration boundaries
  bMin = go03DMin_dry * 2
  bJK = (go03DJKcut_RH[iRHl] * iRHp + go03DJKcut_RH[iRHr] * (1-iRHp)) / scaleRH * 2
  bMax = go03DMax_dry * 2
  
  #' create lists for the output
  outSSEMIS = list()
  outSSEMIS[['SSEMIS']] = list()
  for (iMoment in c('SRF', 'NUM')) {
    outSSEMIS$SSEMIS[[iMoment]] = list()
    for (iMod in c('I', 'J', 'K')) {
      outSSEMIS$SSEMIS[[iMoment]][[iMod]] = array(0.0, dim = c(grid$ncol, grid$nrow, 25))
    }
  }
  
  outSSEMIS$SSEMIS[['MASS']] = list()
  for (iStat in c('WET', 'DRY')) {
    outSSEMIS$SSEMIS$MASS[[iStat]] = list()
    for (iMod in c('I', 'J', 'K')) {
      outSSEMIS$SSEMIS$MASS[[iStat]][[iMod]] = array(0.0, dim = c(grid$ncol, grid$nrow, 25))
    }
  }
  
  #' set units
  outSSEMIS[['UNITS']] = list()
  outSSEMIS$UNITS[['MASS']] = 'g/s'
  outSSEMIS$UNITS[['SRF']] = 'm2/s'
  outSSEMIS$UNITS[['NUM']] = 'number/s'
  
  
  #' determine cells and time steps for which sea salt needs to be emitted
  #' 
  #' We have a 3d-array valSST with SSTs. It has the size (ncol x nrow x ntime).
  #' We would like to put those positions (c,r,t) into one array 'positions' for 
  #' which valSST(c,r,t) is defined. 'positions' should have the size
  #' ('number of valid positions in valSST' x 3). In each row we will have a 
  #' valid position. In column 1 will be 'c', in column 2 will be 'r' and in
  #' column 3 will be 't'.
  # example
  # C = grid$ncol
  # R = grid$nrow
  # T = 25
  # array: C x R x T
  # i = 143 
  # c = ((i-1)%%C)+1 
  # r = (((i-c)/C)%%R)+1 
  # t = (i-c-(r-1)*C)/(C*R)+1
  indices = (1:(grid$ncol*grid$nrow*25))[(valOPEN + valSURF) > 0]
  positions = array(0, dim = c(length(indices), 3))
  positions[,1] = ( ( indices - 1 )%%(grid$ncol) ) + 1 
  positions[,2] = ( ( (indices - positions[,1]) / grid$ncol )%%(grid$nrow) ) + 1 
  positions[,3] = ( indices - positions[,1] - (positions[,2]-1) * grid$ncol ) / ( grid$ncol * grid$nrow ) + 1
  
  #' calculate emissions
  # moved from the loop to here for optimising runtime
  # /8 and /4 for diameter instead of radius
  scaleMassDry = rhoSS * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6) / 8
  scaleSrf = 4 * pi * grid$xcell * grid$ycell * 10^(-6) / 4
  scaleNum = grid$xcell * grid$ycell * 10^6
  
  for (i1 in 1:length(indices)) {
    iCol = positions[i1,1]
    iRow = positions[i1,2]
    iT = positions[i1,3]
    
    tmpU10 = valU10[iCol, iRow, iT]
    tmpOPEN = valOPEN[iCol, iRow]
    tmpSURF = valSURF[iCol, iRow]
    tmpBJK = bJK[iCol, iRow, iT]
    wetFac = scaleRH[iCol, iRow, iT]
    
    #' calculate wind scale factor
    # valU10^3.41 * 3.84 * 10^(-6)  # white cap coverage
    scaleW_GO03 = tmpU10^3.41 * 3.84 * 10^(-6)
    # valU10^3.41 * 1.373           # white cap coverage * factors of Monahan
    # scaleMass = (rhoSS * wetFac^(-3) + (1-wetFac^-3)) * 4/3 * pi * 10^(-12) * grid$xcell * grid$ycell * 10^6
    scaleMassWet = (rhoSS * wetFac^(-3) + (1-wetFac^-3)) * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6) / 8
    # scaleMassDry = rhoSS * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6)
    # (rhoSS * rFac^(-3) + 1 * (1-rFac^-3))   # wet sea salt density
    # 4/3 * pi                                # calculate volume from 3rd moment
    # 10^(-12)                                # convert volume from um^3 into cm^3
    # grid$xcell * grid$ycell * 10^6          # grid cell area in m^2
    # scaleSrf = 4 * pi * 10^(-12) * grid$xcell * grid$ycell * 10^6
    # scaleSrf = 4 * pi * grid$xcell * grid$ycell * 10^(-6)
    # 4 * pi      # calculate surface area from 2nd moment
    # 10^(-12)    # convert surface from um^2 into m^2
    # grid$xcell * grid$ycell * 10^6   # grid cell area in m^2
    # scaleNum = grid$xcell * grid$ycell * 10^6
    
    #' integrate number emissions
    outSSEMIS$SSEMIS$NUM[['J']][iCol, iRow, iT] = scaleNum * integrate(dFdR_GO03, bMin, tmpBJK)$value
    outSSEMIS$SSEMIS$NUM[['K']][iCol, iRow, iT] = scaleNum * integrate(dFdR_GO03, tmpBJK, bMax)$value
    
    #' integrate surface area emissions
    outSSEMIS$SSEMIS$SRF[['J']][iCol, iRow, iT] = scaleSrf * integrate(M2_GO03dry, bMin, tmpBJK)$value
    outSSEMIS$SSEMIS$SRF[['K']][iCol, iRow, iT] = scaleSrf * integrate(M2_GO03dry, tmpBJK, bMax)$value
    
    #' integrate dry ans wet mass emissions
    tmpIJdry = integrate(M3_GO03dry, bMin, tmpBJK)$value
    tmpJKdry = integrate(M3_GO03dry, tmpBJK, bMax)$value
    
    outSSEMIS$SSEMIS$MASS$DRY[['J']][iCol, iRow, iT] = scaleMassDry * tmpIJdry
    outSSEMIS$SSEMIS$MASS$WET[['J']][iCol, iRow, iT] = scaleMassWet * wetFac^3 * tmpIJdry
    outSSEMIS$SSEMIS$MASS$DRY[['K']][iCol, iRow, iT] = scaleMassDry * tmpJKdry
    outSSEMIS$SSEMIS$MASS$WET[['K']][iCol, iRow, iT] = scaleMassWet * wetFac^3 * tmpJKdry
  }
  
  #' return the list
  return(outSSEMIS)
  
}


ssemis_calc_go03 <- cmpfun(ssemis_calc_go03_)
