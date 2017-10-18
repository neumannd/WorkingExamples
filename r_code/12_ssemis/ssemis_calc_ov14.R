#' ssemis_calc_ov14
#' 
#' This function calculates sea salt emissions following 
#' Ovadnevaite et al. (2014) [doi: 10.5194/acp-14-1837-2014]
#' 
#' @author Daniel Neumann
#' @version 4.0.1
#' @date 2015-Nov-06
#' 


#' load libraries and functions ----
library('compiler')
library('ncdf4')
source('../tools/sharqawy2010/SW_tools.R', chdir = TRUE)
source('ssemis_params.R')
source('ssemis_funs.R')


ssemis_calc_ov14_ = function(date, grid, namespace, modeIntegration=1, surfzone=TRUE) {
  print(paste('Integrating day', date, 'using OV14 on grid', grid$name, 'with surfzone =', surfzone, 'and with mode integration', modeIntegration, sep = ' '))
  
  # define needed functions ----
  # standard deviation
  stddev = c(1.37, 1.5, 1.42, 1.53, 1.85)
  # count median diameter
  cmd = c(0.018, 0.041, 0.09, 0.23, 0.83)
  
  # parameters for tnf
  tnf_par1 = c(104.51,0.044,149.64,2.96,0.52)
  tnf_par2 = c(0.556,1.08,0.545,0.79,0.87)
  tnf_par3 = c(1e+5,1e+5,1e+5,1e+5,2e+5)
  # old parameter set (from publication)
#   tnf_par1 = c(104.5,0.0442,149.6,2.96,0.51)
#   tnf_par2 = c(0.556,1.08,0.545,0.79,0.87)
#   tnf_par3 = c(1e+5,1e+5,1e+5,1e+5,2e+5)
  
  # calculate total number fluw (tnf)
  tnf <- function(Re, i1) {
    return(tnf_par1[i1] * (max(Re,tnf_par3[i1]) - tnf_par3[i1])^tnf_par2[i1])
  }

  ptnf <- function(Re, i1) {
    return(tnf_par1[i1] * (pmax.int(Re,tnf_par3[i1]) - tnf_par3[i1])^tnf_par2[i1])
  }
  
  myModes_ = function(iMode, D, tnf) {
    tnf/log10(stddev[iMode]) * exp(-0.5 * (log10(D/cmd[iMode])/log10(stddev[iMode]))^2)
    # Here should be another sqrt(2*pi)^(-1). It is shifted to the calling function in order
    # to reduce computing time.
  }
  myModes = cmpfun(myModes_)

  # calculate source function
  dFdD_OV14_ = function(D, iModes, tnf) {
    # The sqrt(2*pi)^(-1) comes from the functions which is called in the apply.
    # The "D^(-1)" is in the end of the calculation in order to make the order
    #  of the calculations more efficient.
    # return(rowSums(apply(array(iModes, dim = c(length(iModes),1)), MARGIN = 1, FUN = myModes, D = D, Re = Re)) / D)
    tmpVal = rep(0.0, length(D))
    for (iM in iModes) {
      tmpVal = tmpVal + tnf[iM]/log10(stddev[iM]) * exp(-0.5 * (log10(D/cmd[iM])/log10(stddev[iM]))^2)
    }
    return(tmpVal / D)
  }
  dFdD_OV14 = cmpfun(dFdD_OV14_)
  
  # calculate second moment
  M2_OV14_ = function(D, iModes, tnf) {
    # The sqrt(2*pi)^(-1) comes from the functions which is called in the apply.
    # return(D * rowSums(apply(array(iModes, dim = c(length(iModes),1)), MARGIN = 1, FUN = myModes, D = D, Re = Re)))
    tmpVal = rep(0.0, length(D))
    for (iM in iModes) {
      tmpVal = tmpVal + tnf[iM]/log10(stddev[iM]) * exp(-0.5 * (log10(D/cmd[iM])/log10(stddev[iM]))^2)
    }
    return(tmpVal * D)
  }
  M2_OV14 = cmpfun(M2_OV14_)
  
  # calculate third moment
  M3_OV14_ = function(D, iModes, tnf) {
    # The sqrt(2*pi)^(-1) comes from the functions which is called in the apply.
    # return(D^2 * rowSums(apply(array(iModes, dim = c(length(iModes),1)), MARGIN = 1, FUN = myModes, D = D, Re = Re)))
    tmpVal = rep(0.0, length(D))
    for (iM in iModes) {
      tmpVal = tmpVal + tnf[iM]/log10(stddev[iM]) * exp(-0.5 * (log10(D/cmd[iM])/log10(stddev[iM]))^2)
    }
    return(tmpVal * D^2)
  }
  M3_OV14 = cmpfun(M3_OV14_)
  

  # read in input variables ----
  # get SST and SALINITY
  print('reading in SST and Salinity')
  ncId = nc_open(namespace$BSH$path)
  valSST = ncvar_get(ncId, 'SST')       # K
  valSAL = ncvar_get(ncId, 'SALINITY')  # g/kg
  nc_close(ncId)
  
  # get wave data
  print('reading wave data')
  ncId = nc_open(namespace$WAVE$path)
  valHS = ncvar_get(ncId, 'hs')        # m
  valFV = ncvar_get(ncId, 'FV')        # m/s
  nc_close(ncId)
  
  # get OCEAN file data
  print('reading in OCEANfile')
  if(surfzone) oceanType = 'wSZnSL' else oceanType = 'nSZnSL'
  ncId = nc_open(namespace$OCEAN[[oceanType]]$path)
  valOPEN = ncvar_get(ncId, 'OPEN')
  valSURF = ncvar_get(ncId, 'SURF')
  nc_close(ncId)  
  
  # get u10
  print('reading in WSPD10')
  ncId = nc_open(namespace$MC2D$path)
  valU10 = ncvar_get(ncId, 'WSPD10')
  nc_close(ncId)
  
  #' VW = kinematic viscosity water
  #' Equations (22) and (23) from Sharqawy et al. (2010)
  #' 0 < t < 180 C; 0 < S < 0.015 kg/kg
  #' accuracy: +/- 1.5%
  #' unit: m^2/s
  valVW = SWkviscosity(valSST, 'K', valSAL, 'g/kg')
  
  #' calculate RE
  valRE = valFV * valHS / valVW
  
  #' get RH
  print('reading in data for RH calculation')
  valRH = get_relativehumidity_a(date, grid, namespace)
  
  #' radius scale factor depending on RH
  scaleRH = size_scale_rh(valRH)
  
  print('finished with reading data')
  

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

  #' get dry integration boundaries
  bMin = ov14DMin_dry
  bIJ = ov14DIJcut_dry
  bJK = (sp13DJKcut_RH[iRHl] * iRHp + sp13DJKcut_RH[iRHr] * (1-iRHp)) / scaleRH
  bMax = ov14DMax_dry

  #' define mode splitting for modeIntegration == 4
  modalSplit = list('I' = c(1,2),
                    'J' = c(3,4),
                    'K' = c(5))


  # allocate arrays ----
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
  
  
  # calculate indices ----
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
  indices = (1:(grid$ncol*grid$nrow*25))[as.logical((!is.nan(valSST)) * !is.na(valSST) * !is.nan(valSAL) * !is.na(valSAL))]
  positions = array(0, dim = c(length(indices), 3))
  positions[,1] = ( ( indices - 1 )%%(grid$ncol) ) + 1 
  positions[,2] = ( ( (indices - positions[,1]) / grid$ncol )%%(grid$nrow) ) + 1 
  positions[,3] = ( indices - positions[,1] - (positions[,2]-1) * grid$ncol ) / ( grid$ncol * grid$nrow ) + 1

  
  # pre-calculate some values here in order to save computing time in the loop
  cell_area = grid$xcell * grid$ycell * 10^6
  # comes from the size and unit conversion factors, below
  pi_area_unitconvert = pi * grid$xcell * grid$ycell * 10^(-6) 
  # comes from within the integrated functions, above
  logE10_sqrt2pi = log(10)*sqrt(2*pi) 
  # merge everything :-) 
  ONEthroughtANOTHER_A = cell_area / logE10_sqrt2pi
  ONEthroughtANOTHER_B = pi_area_unitconvert / logE10_sqrt2pi


  # iterate dates ----
  for (i1 in 1:length(indices)) {
    #' get indices
    iCol = positions[i1,1]
    iRow = positions[i1,2]
    iT = positions[i1,3]
  
    #' get variables
    tmpRe = valRE[iCol, iRow, iT]
    tmpWater = valOPEN[iCol, iRow] + valSURF[iCol, iRow]
    wetFac = scaleRH[iCol, iRow, iT]
    
    bounds = list('I' = c(bMin, bIJ),
                  'J' = c(bIJ, bJK[iCol, iRow, iT]),
                  'K' = c(bJK[iCol, iRow, iT], bMax))
    
    
    if(is.na(tmpRe)) {
      #' Reynolds number == NA => no ocean
      for (iMode in c('I', 'J', 'K')) {
        outSSEMIS$SSEMIS[['NUM']][[iMode]][iCol,iRow,iT] = 0
        outSSEMIS$SSEMIS[['SRF']][[iMode]][iCol,iRow,iT] = 0
        outSSEMIS$SSEMIS[['MASS']][['DRY']][[iMode]][iCol,iRow,iT] = 0
        outSSEMIS$SSEMIS[['MASS']][['WET']][[iMode]][iCol,iRow,iT] = 0
      }
    } else {
      #' calculate scaling factors
      tmpTNF = ptnf(tmpRe, 1:5)
      
      # scaleMass = (rhoSS * wetFac^(-3) + (1-wetFac^-3)) * 4/3 * pi * 10^(-12) * grid$xcell * grid$ycell * 10^6
      # scaleMassWet = (rhoSS * wetFac^(-3) + (1-wetFac^-3)) * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6)
      # scaleMassWet = (rhoSS + (wetFac^3 - 1)) / 6 * pi * grid$xcell * grid$ycell * 10^(-6)
      scaleMassWet = (rhoSS + (wetFac^3 - 1)) / 6 * ONEthroughtANOTHER_B * tmpWater
      # scaleMassDry = rhoSS * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6)
      # scaleMassDry = rhoSS / 6 * pi * grid$xcell * grid$ycell * 10^(-6)
      scaleMassDry = rhoSS / 6 * ONEthroughtANOTHER_B * tmpWater
      # (rhoSS * rFac^(-3) + 1 * (1-rFac^-3))   # wet sea salt density
      # 4/3 * pi                                # calculate volume from 3rd moment
      # 10^(-12)                                # convert volume from um^3 into cm^3
      # grid$xcell * grid$ycell * 10^6          # grid cell area in m^2
      # wetFac^3                                # we move wetFac^3 out of the integral when calculating 3rd moment
      # 1/8 = 1/2^3                             # we get thrid moment for D_dry = R_80; => we need to divide by 2
      # scaleSrf = 4 * pi * 10^(-12) * grid$xcell * grid$ycell * 10^6
      # scaleSrf = 4 * pi * grid$xcell * grid$ycell * 10^(-6)
      # scaleSrf = scaleSalSrf * wetFac^2 * pi * grid$xcell * grid$ycell * 10^(-6)
      # scaleSrf = pi * grid$xcell * grid$ycell * 10^(-6)
      scaleSrf = ONEthroughtANOTHER_B * tmpWater
      # 4 * pi      # calculate surface area from 2nd moment
      # 10^(-12)    # convert surface from um^2 into m^2
      # grid$xcell * grid$ycell * 10^6   # grid cell area in m^2
      # / 4         # we work with 2*r_dr because source functions are made for r_80
      # wetFac^2    # when the surface is integrated, we move wetFac^2 out of the integral
      # scaleNum = grid$xcell * grid$ycell * 10^6
      scaleNum = ONEthroughtANOTHER_A * tmpWater
      # grid$xcell * grid$ycell * 10^6          # grid cell area in m^2
      
      
      #' integrate source function
      # distinguish between modeIntegration == 4 and other casses
      if (modeIntegration == 4) {
        for (iMode in c('I', 'J', 'K')) {
          tmpForErr = integrate(dFdD_OV14, bMin, bMax, iModes = modalSplit[[iMode]], tnf=tmpTNF, stop.on.error=FALSE)
          tmpNum = tmpForErr$value
          if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                       paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                       paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                       paste('integrate(M0_OV14, ', bMin, ', ', bMax, ')', sep = ''),
                                                       sep = ': '))
          
          tmpForErr = integrate(M2_OV14, bMin, bMax, iModes = modalSplit[[iMode]], tnf=tmpTNF, stop.on.error=FALSE)
          tmpSrf = tmpForErr$value
          if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                       paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                       paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                       paste('integrate(M2_OV14, ', bMin, ', ', bMax, ')', sep = ''),
                                                       sep = ': '))
                                                   
          tmpForErr = integrate(M3_OV14, bMin, bMax, iModes = modalSplit[[iMode]], tnf=tmpTNF, stop.on.error=FALSE)
          tmpMassDry = tmpForErr$value
          if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                       paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                       paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                       paste('integrate(M3_OV14, ', bMin, ', ', bMax, ')', sep = ''),
                                                       sep = ': '))
          
          outSSEMIS$SSEMIS[['NUM']][[iMode]][iCol,iRow,iT] = scaleNum * tmpNum
          outSSEMIS$SSEMIS[['SRF']][[iMode]][iCol,iRow,iT] = scaleSrf * tmpSrf
          outSSEMIS$SSEMIS[['MASS']][['DRY']][[iMode]][iCol,iRow,iT] = scaleMassDry * tmpMassDry
          outSSEMIS$SSEMIS[['MASS']][['WET']][[iMode]][iCol,iRow,iT] = scaleMassWet * tmpMassDry
        }
      } else {
        for (iMode in c('I', 'J', 'K')) {
          tmpNum = integrate(dFdD_OV14, bounds[[iMode]][1], bounds[[iMode]][2], iModes = 1:5, tnf=tmpTNF)$value
          tmpSrf = integrate(M2_OV14, bounds[[iMode]][1], bounds[[iMode]][2], iModes = 1:5, tnf=tmpTNF)$value
          tmpMassDry = integrate(M3_OV14, bounds[[iMode]][1], bounds[[iMode]][2], iModes = 1:5, tnf=tmpTNF)$value
          
          outSSEMIS$SSEMIS[['NUM']][[iMode]][iCol,iRow,iT] = scaleNum * tmpNum
          outSSEMIS$SSEMIS[['SRF']][[iMode]][iCol,iRow,iT] = scaleSrf * tmpSrf
          outSSEMIS$SSEMIS[['MASS']][['DRY']][[iMode]][iCol,iRow,iT] = scaleMassDry * tmpMassDry
          outSSEMIS$SSEMIS[['MASS']][['WET']][[iMode]][iCol,iRow,iT] = scaleMassWet * tmpMassDry
        }
      }
    }
  }
  
  #' return the list
  return(outSSEMIS)
}

ssemis_calc_ov14 = cmpfun(ssemis_calc_ov14_)
