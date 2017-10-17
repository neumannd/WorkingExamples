#' ssemis_calc_sp13
#' 
#' This function calculates sea salt emissions following 
#' Spada et al. (2013) [doi: 10.5194/acp-13-11735-2013]
#'
#' Remarks on solving the integrals:
#'  - MO86 and SM93: cannot be (easily) integrated by hand; especially 2nd 
#'                    and 3rd moments
#'  - MA03: It is a polynomial. Therefore, it is quite easy to integrate it
#'            by hand. However, MA03 is negative for some parts of the third
#'            size interval for which it is defined when SST < 275.6. Hence,
#'            we can solve MA03 directly on the first and second interval,
#'            in general, and on the third interval when SST >= 275.6.
#'
#' @author Daniel Neumann
#' @version 4.0.1
#' @date 2015-Nov-06


#' load libraries and functions ----
library('compiler')
library('ncdf4')
source('ssemis_params.R')
source('ssemis_funs.R')


ssemis_calc_sp13_ = function(date, grid, namespace, modeIntegration = 2, surfzone=TRUE) {
  print(paste('Integrating day', date, 'using SP13 on grid', grid$name, 'with surfzone =', surfzone, 'and with mode integration', modeIntegration, sep = ' '))
  # define needed functions ----
  #' this function gets D_dry as parameter which equals r_80
  dFdR_MA03_ = function(D, SST, iM) {
    return(pmax.int((constMA03_a[iM,5] + constMA03_a[iM,4] * D + constMA03_a[iM,3] * D^2 
             + constMA03_a[iM,2] * D^3 + constMA03_a[iM,1] * D^4) * SST
            + (constMA03_b[iM,5] + constMA03_b[iM,4] * D + constMA03_b[iM,3] * D^2 
               + constMA03_b[iM,2] * D^3 + constMA03_b[iM,1] * D^4), 0, na.rm = TRUE) / D)
  }
  dFdR_MA03 = cmpfun(dFdR_MA03_)
  
  F0_MA03 = function(D1, D2, SST, iM) {
    return((constMA03_a[iM,5]*SST + constMA03_b[iM,5]) * (log(D2) - log(D1))
            + (constMA03_a[iM,4]*SST + constMA03_b[iM,4]) * (D2-D1) 
            + (constMA03_a[iM,3]*SST + constMA03_b[iM,3]) * (D2^2-D1^2) * 0.5
            + (constMA03_a[iM,2]*SST + constMA03_b[iM,2]) * (D2^3-D1^3) / 3
            + (constMA03_a[iM,1]*SST + constMA03_b[iM,1]) * (D2^4-D1^4) * 0.25)
  }
  
  dFdR_SM93_ = function(R) {
    A1 = 10^{0.0676 * tmpU10 + 2.43}
    A2 = 10^{0.959 * sqrt(tmpU10) - 1.476}
    return(A1 * exp(-3.1 * log(R/2.1)^2) + A2 * exp(-3.3 * log(R/9.2)^2))
  }
  dFdR_SM93 = cmpfun(dFdR_SM93_)
  
  dFdR_MO86_ = function(R) {
    B = (0.38 - log10(R))/0.65
    return(R^(-3) * (1 + 0.057 * R^1.05) * 10^(1.19 * exp(-B^2)))
  }
  dFdR_MO86 = cmpfun(dFdR_MO86_)
  
  #' calculate second moments
  #' I removed wetFac^2 (scaling for wet surface area) and added it to
  #' the scale factor which is applied after the integration. Removing it
  #' here may decrease the integration run time because one multiplication
  #' less per inserted 'r' has to be performed.
  M2_MA03 = cmpfun(function(D, SST, iM) { return(D * pmax.int((constMA03_a[iM,5]*SST + constMA03_b[iM,5])
                                                              + (constMA03_a[iM,4]*SST + constMA03_b[iM,4]) * D 
                                                              + (constMA03_a[iM,3]*SST + constMA03_b[iM,3]) * D^2
                                                              + (constMA03_a[iM,2]*SST + constMA03_b[iM,2]) * D^3
                                                              + (constMA03_a[iM,1]*SST + constMA03_b[iM,1]) * D^4 , 0, na.rm = TRUE)) })
  
  F2_MA03 = function(D1, D2, SST, iM) {
    return((constMA03_a[iM,5]*SST + constMA03_b[iM,5]) * (D2^2-D1^2) * 0.5
           + (constMA03_a[iM,4]*SST + constMA03_b[iM,4]) * (D2^3-D1^3) / 3
           + (constMA03_a[iM,3]*SST + constMA03_b[iM,3]) * (D2^4-D1^4) * 0.25
           + (constMA03_a[iM,2]*SST + constMA03_b[iM,2]) * (D2^5-D1^5) * 0.2
           + (constMA03_a[iM,1]*SST + constMA03_b[iM,1]) * (D2^6-D1^6) / 6)
  }
  M2_SM93 = cmpfun(function(R) { return(R^2 * dFdR_SM93(R)) })
  M2_MO86 = cmpfun(function(R) { return(R^2 * dFdR_MO86(R)) })
  
  # calculate third moments
  # We only use the dry volume emission functions because we can multiply
  # wetFac^3 after the integration. This may decrease the run time.
  M3_MA03 = cmpfun(function(D, SST, iM) { return(D^2 * pmax.int((constMA03_a[iM,5]*SST + constMA03_b[iM,5])
                                                              + (constMA03_a[iM,4]*SST + constMA03_b[iM,4]) * D 
                                                              + (constMA03_a[iM,3]*SST + constMA03_b[iM,3]) * D^2
                                                              + (constMA03_a[iM,2]*SST + constMA03_b[iM,2]) * D^3
                                                              + (constMA03_a[iM,1]*SST + constMA03_b[iM,1]) * D^4 , 0, na.rm = TRUE)) })
  F3_MA03 = function(D1, D2, SST, iM) {
    return((constMA03_a[iM,5]*SST + constMA03_b[iM,5]) * (D2^3-D1^3) / 3
           + (constMA03_a[iM,4]*SST + constMA03_b[iM,4]) * (D2^4-D1^4) * 0.25
           + (constMA03_a[iM,3]*SST + constMA03_b[iM,3]) * (D2^5-D1^5) * 0.2
           + (constMA03_a[iM,2]*SST + constMA03_b[iM,2]) * (D2^6-D1^6) / 6
           + (constMA03_a[iM,1]*SST + constMA03_b[iM,1]) * (D2^7-D1^7) / 7)
  }
  M3_SM93 = cmpfun(function(R) { return(R^3 * dFdR_SM93(R)) })
  M3_MO86 = cmpfun(function(R) { return(R^3 * dFdR_MO86(R)) })
  
  int_M0_MA03int3 = function(D1, D2, SST) {
    if (SST < 275.6) {
      return(integrate(dFdR_MA03, D1, D2, SST = SST, iM = 3, stop.on.error=FALSE))
    } else {return(list(message = 'OK', value = F0_MA03(D1,D2,SST,3)))}
  }
  int_M2_MA03int3 = function(D1, D2, SST) {
    if (SST < 275.6) {
      return(integrate(M2_MA03, D1, D2, SST = SST, iM = 3, stop.on.error=FALSE))
    } else {return(list(message = 'OK', value = F2_MA03(D1,D2,SST,3)))}
  }
  int_M3_MA03int3 = function(D1, D2, SST) {
    if (SST < 275.6) {
      return(integrate(M3_MA03, D1, D2, SST = SST, iM = 3, stop.on.error=FALSE))
    } else {return(list(message = 'OK', value = F3_MA03(D1,D2,SST,3)))}
  }
  
  # read in input variables ----
  # get SST and SALINITY
  print('reading in SST and Salinity')
  ncId = nc_open(namespace$BSH$path)
  valSST = ncvar_get(ncId, 'SST')
  valSAL = ncvar_get(ncId, 'SALINITY')
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
  
  # get RH
  print('reading in data for RH calculation')
  valRH = get_relativehumidity_a(date, grid, namespace)
  
  print('finished with reading data')
  
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
  bMin = sp13DMin_dry
  bIJ = sp13DIJcut_dry
  bMA03_12 = ma03D12_dry
  bMA03_23 = ma03D23_dry
  bJK = (sp13DJKcut_RH[iRHl] * iRHp + sp13DJKcut_RH[iRHr] * (1-iRHp)) / scaleRH * 2
  bMA03_30 = ma03D30_dry
  bMO86_min = ma03D30_dry
  bMO86_max = mo86Dmax_dry
  bSM93_min = sm93Din_dry
  bSM93_max = sm93Dmax_dry
  bMax = sp13DMax_dry
  
  
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
  indices = (1:(grid$ncol*grid$nrow*25))[as.logical((!is.nan(valSST)) * !is.na(valSST) * !is.nan(valSAL) * !is.na(valSAL))]
  positions = array(0, dim = c(length(indices), 3))
  positions[,1] = ( ( indices - 1 )%%(grid$ncol) ) + 1 
  positions[,2] = ( ( (indices - positions[,1]) / grid$ncol )%%(grid$nrow) ) + 1 
  positions[,3] = ( indices - positions[,1] - (positions[,2]-1) * grid$ncol ) / ( grid$ncol * grid$nrow ) + 1
  
  
  # pre-calculate some values here in order to save computing time in the loop
  scaleNumBase = grid$xcell * grid$ycell * 10^6
  # comes from the size and unit conversion factors, below
  pi_area_tenEminusSIX = pi * grid$xcell * grid$ycell * 10^(-6) 
  
  
  # iterate dates ----
  for (i1 in 1:length(indices)) {
    iCol = positions[i1,1]
    iRow = positions[i1,2]
    iT = positions[i1,3]
    
    tmpSST = valSST[iCol, iRow, iT]
    tmpSST[is.na(tmpSST)] = 273
    tmpSST = max(271, min(298, tmpSST))
    tmpSAL = max(0, valSAL[iCol, iRow, iT], na.rm = TRUE)
    tmpU10 = valU10[iCol, iRow, iT]
    tmpWATER = valOPEN[iCol, iRow] + valSURF[iCol, iRow]
    tmpOPEN = valOPEN[iCol, iRow]
    tmpSURF = valSURF[iCol, iRow]
    wetFac = scaleRH[iCol, iRow, iT]
    tmpBJK = bJK[iCol, iRow, iT]
    
    if(modeIntegration%%3 == 0) {
      scaleSalVol = tmpSAL/35
      scaleSalSrf = scaleSalVol^(2/3)
      scaleSalRad = scaleSalVol^(1/3)
      scaleSalNum = 1
    } else if (modeIntegration%%3 == 2) {
      scaleSalVol = tmpSAL/35
      scaleSalSrf = scaleSalVol^(2/3)
      scaleSalRad = scaleSalVol^(1/3)
      scaleSalNum = 1
    } else if(modeIntegration%%3 == 1) {
      scaleSalVol = tmpSAL/35
      scaleSalSrf = scaleSalVol
      scaleSalRad = scaleSalVol
      scaleSalNum = scaleSalVol
    } else {
      scaleSalVol = 1
      scaleSalSrf = 1
      scaleSalRad = 1
      scaleSalNum = 1
    }
    
    #' calculate wind scale factor
    # scaleW_MA03 = valU10^3.41 * 3.84 * 10^(-6) * grid$xcell * grid$ycell * 10^6
    # scaleW_MA03 = tmpU10^3.41 * 3.84 * 10^(-6)
    # valU10^3.41 * 3.84 * 10^(-6)  # white cap coverage
    # scaleW_MO86 = tmpU10^3.41 * 3.84 * 10^(-6)
    # valU10^3.41 * 1.373           # white cap coverage * factors of Monahan
    # scaleW_SM93 = 1
    # nothing   
    # scaleMass = (rhoSS * wetFac^(-3) + (1-wetFac^-3)) * 4/3 * pi * 10^(-12) * grid$xcell * grid$ycell * 10^6
    # scaleMassWet = (rhoSS * wetFac^(-3) + (1-wetFac^-3)) * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6)
    scaleMassWet = scaleSalVol * (rhoSS + (wetFac^3 - 1)) / 6 * pi_area_tenEminusSIX
    # scaleMassDry = rhoSS * 4/3 * pi * grid$xcell * grid$ycell * 10^(-6)
    scaleMassDry = scaleSalVol * rhoSS / 6 * pi_area_tenEminusSIX
    # (rhoSS * rFac^(-3) + 1 * (1-rFac^-3))   # wet sea salt density
    # 4/3 * pi                                # calculate volume from 3rd moment
    # 10^(-12)                                # convert volume from um^3 into cm^3
    # grid$xcell * grid$ycell * 10^6          # grid cell area in m^2
    # wetFac^3                                # we move wetFac^3 out of the integral when calculating 3rd moment
    # scaleSrf = 4 * pi * 10^(-12) * grid$xcell * grid$ycell * 10^6
    # scaleSrf = 4 * pi * grid$xcell * grid$ycell * 10^(-6)
    # scaleSrf = scaleSalSrf * wetFac^2 * pi * grid$xcell * grid$ycell * 10^(-6)
    scaleSrf = scaleSalSrf * pi_area_tenEminusSIX
    # 4 * pi      # calculate surface area from 2nd moment
    # 10^(-12)    # convert surface from um^2 into m^2
    # grid$xcell * grid$ycell * 10^6   # grid cell area in m^2
    # / 4         # we work with 2*r_dr because source functions are made for r_80
    # wetFac^2    # when the surface is integrated, we move wetFac^2 out of the integral
    # scaleNum = grid$xcell * grid$ycell * 10^6
    scaleNum = scaleSalNum * scaleNumBase
    # /8 and /4 for diameter instead of radius
    # grid$xcell * grid$ycell * 10^6          # grid cell area in m^2
    
    # moved from functions which are integrated to here
    scaleW = tmpU10^3.41 * 3.84 * 10^(-6)
    scaleWOCEAN = scaleW * tmpOPEN + tmpSURF
    scaleOCEAN = tmpOPEN + tmpSURF
    scMA03 = scaleWOCEAN / log(10)
    scSM93 = scaleOCEAN
    scMO86 = 3.5755 * 10^5 * scaleWOCEAN
    
    # MARKER
    fMarkIntegrate <- function(x) {return(x)}
    
    
    if (modeIntegration == 3) {
      # integrate: modeIntegration == 3 -----
      #' integrate number emissions for Martensson et al. (2003) 
      tmpNumI = (F0_MA03(bMin                         , min(max(bIJ/scaleSalRad, bMin), bMA03_12), SST = tmpSST, iM = 1) + 
                   F0_MA03(min(bIJ/scaleSalRad, bMA03_12), min(bIJ/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                   int_M0_MA03int3(min(bIJ/scaleSalRad, bMA03_23), min(bIJ/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpNumJ = (F0_MA03(min(bIJ/scaleSalRad, bMA03_12)               , min(tmpBJK/scaleSalRad, bMA03_12), SST = tmpSST, iM = 1) + 
                   F0_MA03(min(max(bIJ/scaleSalRad, bMA03_12), bMA03_23), min(tmpBJK/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                   int_M0_MA03int3(min(max(bIJ/scaleSalRad, bMA03_23), bMA03_30), min(tmpBJK/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpForErr = int_M0_MA03int3(min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30)           , bMA03_30, SST = tmpSST)
      tmpNumK = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(dFdR_MA03_3, ', min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30), ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate surface area emissions for Martensson et al. (2003)
      tmpSrfIdry = (F2_MA03(bMin                         , min(max(bIJ/scaleSalRad, bMin), bMA03_12), SST = tmpSST, iM = 1) + 
                      F2_MA03(min(bIJ/scaleSalRad, bMA03_12), min(bIJ/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                      int_M2_MA03int3(min(bIJ/scaleSalRad, bMA03_23), min(bIJ/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpSrfJdry = (F2_MA03(min(bIJ/scaleSalRad, bMA03_12)               , min(tmpBJK/scaleSalRad, bMA03_12), SST = tmpSST, iM = 1) + 
                      F2_MA03(min(max(bIJ/scaleSalRad, bMA03_12), bMA03_23), min(tmpBJK/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                      int_M2_MA03int3(min(max(bIJ/scaleSalRad, bMA03_23), bMA03_30), min(tmpBJK/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpForErr = int_M2_MA03int3(min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30)           , bMA03_30, SST = tmpSST)
      tmpSrfKdry = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(M2_MA03_3, ', min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30), ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate dry mass emissions for Martensson et al. (2003)
      tmpMassIdry = (F3_MA03(bMin                          , min(max(bIJ/scaleSalRad, bMin), bMA03_12), SST = tmpSST, iM = 1) + 
                       F3_MA03(min(bIJ/scaleSalRad, bMA03_12), min(bIJ/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                       int_M3_MA03int3(min(bIJ/scaleSalRad, bMA03_23), min(bIJ/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpMassJdry = (F3_MA03(min(bIJ/scaleSalRad, bMA03_12)               , min(tmpBJK/scaleSalRad, bMA03_12), SST = tmpSST, iM = 1) + 
                       F3_MA03(min(max(bIJ/scaleSalRad, bMA03_12), bMA03_23), min(tmpBJK/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                       int_M3_MA03int3(min(max(bIJ/scaleSalRad, bMA03_23), bMA03_30), min(tmpBJK/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpForErr = int_M0_MA03int3(min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30)           , bMA03_30, SST = tmpSST)
      tmpMassKdry = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, 'iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(M3_MA03_3, ', min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30), ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate emissions for Monahan et al. (1986) and Smith et al. (1993)
      if(tmpU10 >= 9) {
        tmpNumI = scMA03 * tmpNumI + scSM93 * integrate(dFdR_SM93, min(bIJ/scaleSalRad, bMA03_30), min(bIJ/scaleSalRad, bMax))$value
        tmpNumJ = scMA03 * tmpNumJ + scSM93 * integrate(dFdR_SM93, min(max(bIJ/scaleSalRad, bMA03_30), bMax), min(max(tmpBJK/scaleSalRad, bMA03_30), bMax))$value
        tmpNumK = scMA03 * tmpNumK + scSM93 * integrate(dFdR_SM93, min(max(tmpBJK/scaleSalRad, bMA03_30), bMax), bMax)$value
        tmpSrfIdry = scMA03 * tmpSrfIdry + scSM93 * integrate(M2_SM93, min(bIJ/scaleSalRad, bMA03_30), min(bIJ/scaleSalRad, bMax))$value
        tmpSrfJdry = scMA03 * tmpSrfJdry + scSM93 * integrate(M2_SM93, min(max(bIJ/scaleSalRad, bMA03_30), bMax), min(max(tmpBJK/scaleSalRad, bMA03_30), bMax))$value
        tmpSrfKdry = scMA03 * tmpSrfKdry + scSM93 * integrate(M2_SM93, min(max(tmpBJK/scaleSalRad, bMA03_30), bMax), bMax)$value
        tmpMassIdry = scMA03 * tmpMassIdry + scSM93 * integrate(M3_SM93, min(bIJ/scaleSalRad, bMA03_30), min(bIJ/scaleSalRad, bMax))$value
        tmpMassJdry = scMA03 * tmpMassJdry + scSM93 * integrate(M3_SM93, min(max(bIJ/scaleSalRad, bMA03_30), bMax), min(max(tmpBJK/scaleSalRad, bMA03_30), bMax))$value
        tmpMassKdry = scMA03 * tmpMassKdry + scSM93 * integrate(M3_SM93, min(max(tmpBJK/scaleSalRad, bMA03_30), bMax), bMax)$value
      } else {
        tmpNumI = scMA03 * tmpNumI + scMO86 * integrate(dFdR_MO86, min(bIJ/scaleSalRad, bMA03_30), min(bIJ/scaleSalRad, bMax))$value
        tmpNumJ = scMA03 * tmpNumJ + scMO86 * integrate(dFdR_MO86, min(max(bIJ/scaleSalRad, bMA03_30), bMax),min(max(tmpBJK/scaleSalRad, bMA03_30), bMax))$value
        tmpNumK = scMA03 * tmpNumK + scMO86 * integrate(dFdR_MO86, min(max(tmpBJK/scaleSalRad, bMA03_30), bMax), bMax)$value
        tmpSrfIdry = scMA03 * tmpSrfIdry + scMO86 * integrate(M2_MO86, min(bIJ/scaleSalRad, bMA03_30), min(bIJ/scaleSalRad, bMax))$value
        tmpSrfJdry = scMA03 * tmpSrfJdry + scMO86 * integrate(M2_MO86, min(max(bIJ/scaleSalRad, bMA03_30), bMax), min(max(tmpBJK/scaleSalRad, bMA03_30), bMax))$value
        tmpSrfKdry = scMA03 * tmpSrfKdry + scMO86 * integrate(M2_MO86, min(max(tmpBJK/scaleSalRad, bMA03_30), bMax), bMax)$value
        tmpMassIdry = scMA03 * tmpMassIdry + scMO86 * integrate(M3_MO86, min(bIJ/scaleSalRad, bMA03_30), min(bIJ/scaleSalRad, bMax))$value
        tmpMassJdry = scMA03 * tmpMassJdry + scMO86 * integrate(M3_MO86, min(max(bIJ/scaleSalRad, bMA03_30), bMax), min(max(tmpBJK/scaleSalRad, bMA03_30), bMax))$value
        tmpMassKdry = scMA03 * tmpMassKdry + scMO86 * integrate(M3_MO86, min(max(tmpBJK/scaleSalRad, bMA03_30), bMax), bMax)$value
      }
    } else if (modeIntegration %in% c(6,9) ) {
      # integrate: modeIntegration == 6 || 7 -----
      #' integrate number emissions for Martensson et al. (2003) 
      tmpNumI = (F0_MA03(bMin                         , min(max(bIJ/scaleSalRad, bMin), bMA03_12), SST = tmpSST, iM = 1) + 
                   F0_MA03(min(bIJ/scaleSalRad, bMA03_12), min(bIJ/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                   int_M0_MA03int3(min(bIJ/scaleSalRad, bMA03_23), min(bIJ/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpNumJ = (F0_MA03(min(bIJ/scaleSalRad, bMA03_12)               , min(tmpBJK/scaleSalRad, bMA03_12), SST = tmpSST, iM = 1) + 
                   F0_MA03(min(max(bIJ/scaleSalRad, bMA03_12), bMA03_23), min(tmpBJK/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                   int_M0_MA03int3(min(max(bIJ/scaleSalRad, bMA03_23), bMA03_30), min(tmpBJK/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpForErr = int_M0_MA03int3(min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30)           , bMA03_30, SST = tmpSST)
      tmpNumK = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(dFdR_MA03_3, ', min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30), ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate surface area emissions for Martensson et al. (2003)
      tmpSrfIdry = (F2_MA03(bMin                         , min(max(bIJ/scaleSalRad, bMin), bMA03_12), SST = tmpSST, iM = 1) + 
                      F2_MA03(min(bIJ/scaleSalRad, bMA03_12), min(bIJ/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                      int_M2_MA03int3(min(bIJ/scaleSalRad, bMA03_23), min(bIJ/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpSrfJdry = (F2_MA03(min(bIJ/scaleSalRad, bMA03_12)               , min(tmpBJK/scaleSalRad, bMA03_12), SST = tmpSST, iM = 1) + 
                      F2_MA03(min(max(bIJ/scaleSalRad, bMA03_12), bMA03_23), min(tmpBJK/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                      int_M2_MA03int3(min(max(bIJ/scaleSalRad, bMA03_23), bMA03_30), min(tmpBJK/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpForErr = int_M2_MA03int3(min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30)           , bMA03_30, SST = tmpSST)
      tmpSrfKdry = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(M2_MA03_3, ', min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30), ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate dry mass emissions for Martensson et al. (2003)
      tmpMassIdry = (F3_MA03(bMin                          , min(max(bIJ/scaleSalRad, bMin), bMA03_12), SST = tmpSST, iM = 1) + 
                       F3_MA03(min(bIJ/scaleSalRad, bMA03_12), min(bIJ/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                       int_M3_MA03int3(min(bIJ/scaleSalRad, bMA03_23), min(bIJ/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpMassJdry = (F3_MA03(min(bIJ/scaleSalRad, bMA03_12)               , min(tmpBJK/scaleSalRad, bMA03_12), SST = tmpSST, iM = 1) + 
                       F3_MA03(min(max(bIJ/scaleSalRad, bMA03_12), bMA03_23), min(tmpBJK/scaleSalRad, bMA03_23), SST = tmpSST, iM = 2) + 
                       int_M3_MA03int3(min(max(bIJ/scaleSalRad, bMA03_23), bMA03_30), min(tmpBJK/scaleSalRad, bMA03_30), SST = tmpSST)$value
      )
      tmpForErr = int_M0_MA03int3(min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30)           , bMA03_30, SST = tmpSST)
      tmpMassKdry = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, 'iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(M3_MA03_3, ', min(max(tmpBJK/scaleSalRad,bMA03_23), bMA03_30), ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      
      #' integrate emissions for Monahan et al. (1986) and Smith et al. (1993)
      #' NOTE:  MA03 is defined up till 2.8 um.
      #'        MO86 is defined from 0.8 to 8 um.
      #'        SM93 is defined from 5 to 20 um.
      #'        All values are giben as dry diameter (or radius at 80% RH).
      #' THUS:  MO86 can be integrated from 2.8 to 5 um every time and
      #'        MO86 can be integrated from 2.8 to 8 um if u10 < 9 m/s.
      #'        SM93 can be integrated from 8 to 20 um if u10 >= 9 m/s.
      #'        On the range from 5 um to 8 um we need to integrate
      #'          max(MO86,SM93) if u10 >= 9 m/s.
      #' BUT:   integrate(MO86)/integrate(max(MO86,SM93)) on the interval
      #'          5 to 8 um is close to 1 which means that we can just
      #'          integrate MO86. The same states for 
      #'          integrate(D^3 * MO86)/integrate(D^3 * max(MO86,SM93))
      #'          which is needed for calculating the volume flux.
      #' THEREFORE: We integrate
      #'        MO86 from 2.8 to 8 um (every time) and
      #'        SM93 from 8 to 20 um if u10 >= 9 m/s.
      
      #' integrate emissions for Monahan et al. (1986)
      #' set integration boundaries: it makes the code clearer to read
      ibMO86_I_left = min(bIJ/scaleSalRad, bMA03_30)
      ibMO86_I_right = min(bIJ/scaleSalRad, bMO86_max)
      ibMO86_J_left = min(max(bIJ/scaleSalRad, bMA03_30), bMO86_max)
      ibMO86_J_right = min(max(tmpBJK/scaleSalRad, bMA03_30), bMO86_max)
      ibMO86_K_left = min(max(tmpBJK/scaleSalRad, bMA03_30), bMO86_max)
      ibMO86_K_right = bMO86_max
      
      tmpNumI = scMA03 * tmpNumI + scMO86 * integrate(dFdR_MO86, ibMO86_I_left, ibMO86_I_right)$value
      tmpNumJ = scMA03 * tmpNumJ + scMO86 * integrate(dFdR_MO86, ibMO86_J_left,ibMO86_J_right)$value
      tmpNumK = scMA03 * tmpNumK + scMO86 * integrate(dFdR_MO86, ibMO86_K_left, ibMO86_K_right)$value
      tmpSrfIdry = scMA03 * tmpSrfIdry + scMO86 * integrate(M2_MO86, ibMO86_I_left, ibMO86_I_right)$value
      tmpSrfJdry = scMA03 * tmpSrfJdry + scMO86 * integrate(M2_MO86, ibMO86_J_left, ibMO86_J_right)$value
      tmpSrfKdry = scMA03 * tmpSrfKdry + scMO86 * integrate(M2_MO86, ibMO86_K_left, ibMO86_K_right)$value
      tmpMassIdry = scMA03 * tmpMassIdry + scMO86 * integrate(M3_MO86, ibMO86_I_left, ibMO86_I_right)$value
      tmpMassJdry = scMA03 * tmpMassJdry + scMO86 * integrate(M3_MO86, ibMO86_J_left, ibMO86_J_right)$value
      tmpMassKdry = scMA03 * tmpMassKdry + scMO86 * integrate(M3_MO86, ibMO86_K_left, ibMO86_K_right)$value
      
      
      #' integrate emissions for Smith et al. (1993)
      if(tmpU10 >= 9 && modeIntegration != 9 ) {
        # set integration boundaries: it makes the code clearer to read
        ibSM93_I_left = min(bIJ/scaleSalRad, bMO86_max)
        ibSM93_I_right = min(bIJ/scaleSalRad, bSM93_max)
        ibSM93_J_left = min(max(bIJ/scaleSalRad, bMO86_max), bSM93_max)
        ibSM93_J_right = min(max(tmpBJK/scaleSalRad, bMO86_max), bSM93_max)
        ibSM93_K_left = min(max(tmpBJK/scaleSalRad, bMO86_max), bSM93_max)
        ibSM93_K_right = bSM93_max
          
        tmpNumI = tmpNumI + scSM93 * integrate(dFdR_SM93, ibSM93_I_left, ibSM93_I_right)$value
        tmpNumJ = tmpNumJ + scSM93 * integrate(dFdR_SM93, ibSM93_J_left, ibSM93_J_right)$value
        tmpNumK = tmpNumK + scSM93 * integrate(dFdR_SM93, ibSM93_K_left, ibSM93_K_right)$value
        tmpSrfIdry = tmpSrfIdry + scSM93 * integrate(M2_SM93, ibSM93_I_left, ibSM93_I_right)$value
        tmpSrfJdry = tmpSrfJdry + scSM93 * integrate(M2_SM93, ibSM93_J_left, ibSM93_J_right)$value
        tmpSrfKdry = tmpSrfKdry + scSM93 * integrate(M2_SM93, ibSM93_K_left, ibSM93_K_right)$value
        tmpMassIdry = tmpMassIdry + scSM93 * integrate(M3_SM93, ibSM93_I_left, ibSM93_I_right)$value
        tmpMassJdry = tmpMassJdry + scSM93 * integrate(M3_SM93, ibSM93_J_left, ibSM93_J_right)$value
        tmpMassKdry = tmpMassKdry + scSM93 * integrate(M3_SM93, ibSM93_K_left, ibSM93_K_right)$value
      } else {
      }
    } else if(modeIntegration %in% c(1,2)) {
      # integrate: modeIntegration other -----
      #' integrate number emissions
      tmpNumI = F0_MA03(bMin, bIJ, SST = tmpSST, iM = 1)
      tmpNumJ = (F0_MA03(bIJ, bMA03_12, SST = tmpSST, iM = 1) +
                   F0_MA03(bMA03_12, bMA03_23, SST = tmpSST, iM = 2) +
                   int_M0_MA03int3(bMA03_23, tmpBJK, SST = tmpSST)$value)
      tmpForErr = int_M0_MA03int3(tmpBJK, bMA03_30, SST = tmpSST)
      tmpNumK = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(dFdR_MA03_3, ', tmpBJK, ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate surface area emissions
      tmpSrfIdry = F2_MA03(bMin, bIJ, SST = tmpSST, iM = 1)
      tmpSrfJdry = (F2_MA03(bIJ, bMA03_12, SST = tmpSST, iM = 1) +
                      F2_MA03(bMA03_12, bMA03_23, SST = tmpSST, iM = 2) +
                    integrate(M2_MA03, bMA03_23, tmpBJK, SST = tmpSST, iM = 3)$value)
      tmpSrfKdry = integrate(M2_MA03, tmpBJK, bMA03_30, SST = tmpSST, iM = 3)$value
      
      #' integrate dry ans wet mass emissions
      tmpMassIdry = F3_MA03(bMin, bIJ, SST = tmpSST, iM = 1)
      tmpMassJdry = (F3_MA03(bIJ, bMA03_12, SST = tmpSST, iM = 1) +
                       F3_MA03(bMA03_12, bMA03_23, SST = tmpSST, iM = 2) +
                     integrate(M3_MA03, bMA03_23, tmpBJK, SST = tmpSST, iM = 3)$value)
      tmpMassKdry = integrate(M3_MA03, tmpBJK, bMA03_30, SST = tmpSST, iM = 3)$value
      
      tmpNumI = scMA03 * tmpNumI
      tmpNumJ = scMA03 * tmpNumJ
      tmpSrfIdry = scMA03 * tmpSrfIdry
      tmpSrfJdry = scMA03 * tmpSrfJdry
      tmpMassIdry = scMA03 * tmpMassIdry
      tmpMassJdry = scMA03 * tmpMassJdry
      
      if(tmpU10 >= 9) {
        tmpNumK = scMA03 * tmpNumK + scSM93 * integrate(dFdR_SM93, bMA03_30, bMax)$value
        tmpSrfKdry = scMA03 * tmpSrfKdry + scSM93 * integrate(M2_SM93, bMA03_30, bMax)$value
        tmpMassKdry = scMA03 * tmpMassKdry + scSM93 * integrate(M3_SM93, bMA03_30, bMax)$value
      } else {
        tmpNumK = scMA03 * tmpNumK + scMO86 * integrate(dFdR_MO86, bMA03_30, bMax)$value
        tmpMassKdry = scMA03 * tmpMassKdry + scMO86 * integrate(M3_MO86, bMA03_30, bMax)$value
        tmpSrfKdry = scMA03 * tmpSrfKdry + scMO86 * integrate(M2_MO86, bMA03_30, bMax)$value
      }
    } else if(modeIntegration %in% c(4,5,7,8)) {
      # integrate: modeIntegration other -----
      #' integrate number emissions
      tmpNumI = F0_MA03(bMin, bIJ, SST = tmpSST, iM = 1)
      tmpNumJ = (F0_MA03(bIJ, bMA03_12, SST = tmpSST, iM = 1) +
                   F0_MA03(bMA03_12, bMA03_23, SST = tmpSST, iM = 2) +
                   int_M0_MA03int3(bMA03_23, tmpBJK, SST = tmpSST)$value)
      tmpForErr = int_M0_MA03int3(tmpBJK, bMA03_30, SST = tmpSST)
      tmpNumK = tmpForErr$value
      if (tmpForErr$message != 'OK') warning(paste(tmpForErr$message, 
                                                   paste('date=', date, ', iT=', iT, ', iRow=',iRow,', iCol=',iCol, sep = ''), 
                                                   paste('modeIntegration=', modeIntegration, ', surfzone=', surfzone, sep = ''), 
                                                   paste('integrate(dFdR_MA03_3, ', tmpBJK, ', ', bMA03_30, ')', sep = ''),
                                                   sep = ': '))
      
      #' integrate surface area emissions
      tmpSrfIdry = F2_MA03(bMin, bIJ, SST = tmpSST, iM = 1)
      tmpSrfJdry = (F2_MA03(bIJ, bMA03_12, SST = tmpSST, iM = 1) +
                      F2_MA03(bMA03_12, bMA03_23, SST = tmpSST, iM = 2) +
                      integrate(M2_MA03, bMA03_23, tmpBJK, SST = tmpSST, iM = 3)$value)
      tmpSrfKdry = integrate(M2_MA03, tmpBJK, bMA03_30, SST = tmpSST, iM = 3)$value
      
      #' integrate dry ans wet mass emissions
      tmpMassIdry = F3_MA03(bMin, bIJ, SST = tmpSST, iM = 1)
      tmpMassJdry = (F3_MA03(bIJ, bMA03_12, SST = tmpSST, iM = 1) +
                       F3_MA03(bMA03_12, bMA03_23, SST = tmpSST, iM = 2) +
                       integrate(M3_MA03, bMA03_23, tmpBJK, SST = tmpSST, iM = 3)$value)
      tmpMassKdry = integrate(M3_MA03, tmpBJK, bMA03_30, SST = tmpSST, iM = 3)$value
      
      tmpNumI = scMA03 * tmpNumI
      tmpNumJ = scMA03 * tmpNumJ
      tmpSrfIdry = scMA03 * tmpSrfIdry
      tmpSrfJdry = scMA03 * tmpSrfJdry
      tmpMassIdry = scMA03 * tmpMassIdry
      tmpMassJdry = scMA03 * tmpMassJdry
      
      
      #' integrate emissions for Monahan et al. (1986) and Smith et al. (1993)
      #' NOTE:  MA03 is defined up till 2.8 um.
      #'        MO86 is defined from 0.8 to 8 um.
      #'        SM93 is defined from 5 to 20 um.
      #'        All values are giben as dry diameter (or radius at 80% RH).
      #' THUS:  MO86 can be integrated from 2.8 to 5 um every time and
      #'        MO86 can be integrated from 2.8 to 8 um if u10 < 9 m/s.
      #'        SM93 can be integrated from 8 to 20 um if u10 >= 9 m/s.
      #'        On the range from 5 um to 8 um we need to integrate
      #'          max(MO86,SM93) if u10 >= 9 m/s.
      #' BUT:   integrate(MO86)/integrate(max(MO86,SM93)) on the interval
      #'          5 to 8 um is close to 1 which means that we can just
      #'          integrate MO86. The same states for 
      #'          integrate(D^3 * MO86)/integrate(D^3 * max(MO86,SM93))
      #'          which is needed for calculating the volume flux.
      #' THEREFORE: We integrate
      #'        MO86 from 2.8 to 8 um (every time) and
      #'        SM93 from 8 to 20 um if u10 >= 9 m/s.
      
      tmpNumK = scMA03 * tmpNumK + scMO86 * integrate(dFdR_MO86, bMA03_30, bMO86_max)$value
      tmpMassKdry = scMA03 * tmpMassKdry + scMO86 * integrate(M3_MO86, bMA03_30, bMO86_max)$value
      tmpSrfKdry = scMA03 * tmpSrfKdry + scMO86 * integrate(M2_MO86, bMA03_30, bMO86_max)$value
      
      if(tmpU10 >= 9 && !(modeIntegration %in% c(7,8))) {
        tmpNumK = tmpNumK + scSM93 * integrate(dFdR_SM93, bMO86_max, bSM93_max)$value
        tmpSrfKdry = tmpSrfKdry + scSM93 * integrate(M2_SM93, bMO86_max, bSM93_max)$value
        tmpMassKdry = tmpMassKdry + scSM93 * integrate(M3_SM93, bMO86_max, bSM93_max)$value
      }
      
    } else {
      stop(paste('Integration mode no', formatC(modeIntegration, format = 'd'), 'was set by user but is not implemented.', sep = ' '))
    }
    
    if (tmpSrfIdry < 0 || tmpSrfJdry < 0 || tmpSrfKdry < 0) {
      warning(paste(ssemis_calc_sp13_name, ': Negative surface emissions in cell (col, row time):', iCol, iRow, iT, sep = ' '))
    }    

    outSSEMIS$SSEMIS$NUM[['I']][iCol, iRow, iT] = scaleNum * tmpNumI
    outSSEMIS$SSEMIS$NUM[['J']][iCol, iRow, iT] = scaleNum * tmpNumJ
    outSSEMIS$SSEMIS$NUM[['K']][iCol, iRow, iT] = scaleNum * tmpNumK
    outSSEMIS$SSEMIS$SRF[['I']][iCol, iRow, iT] = scaleSrf * tmpSrfIdry
    outSSEMIS$SSEMIS$SRF[['J']][iCol, iRow, iT] = scaleSrf * tmpSrfJdry
    outSSEMIS$SSEMIS$SRF[['K']][iCol, iRow, iT] = scaleSrf * tmpSrfKdry
    outSSEMIS$SSEMIS$MASS$DRY[['I']][iCol, iRow, iT] = scaleMassDry * tmpMassIdry
    outSSEMIS$SSEMIS$MASS$WET[['I']][iCol, iRow, iT] = scaleMassWet * tmpMassIdry 
    outSSEMIS$SSEMIS$MASS$DRY[['J']][iCol, iRow, iT] = scaleMassDry * tmpMassJdry
    outSSEMIS$SSEMIS$MASS$WET[['J']][iCol, iRow, iT] = scaleMassWet * tmpMassJdry
    outSSEMIS$SSEMIS$MASS$DRY[['K']][iCol, iRow, iT] = scaleMassDry * tmpMassKdry
    outSSEMIS$SSEMIS$MASS$WET[['K']][iCol, iRow, iT] = scaleMassWet * tmpMassKdry
  }
  
  #' return the list
  return(outSSEMIS)
  
}


ssemis_calc_sp13 <- cmpfun(ssemis_calc_sp13_)
