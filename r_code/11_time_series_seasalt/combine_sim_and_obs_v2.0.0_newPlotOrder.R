# load libraries ----
library('ncdf4')
library('cmaqtools')
library('ctmeval')

source('./handy_functions.R')
source('./combine_sim_and_obs_special_v1.0.0.R')
source('../../65_R/78_tools/getYlim.R')
source('../../65_R/78_tools/make_daily_mean.R')

# configuration ----
GRID_NAME='CD24'
myGrid = griddesc(GRID_NAME)
DBaccess <- list(name="***",uid="***",pwd="***")
setup = 'effectSeaSalt.v5'
mech = 'cb05tucl_ae5_aq_ssa'
strYear = '2008'

# load/save data ----
### old file: inData_SIM_OBS_pubStations_allSpecs_std_newerSSEMIS.RData
## save(list = ls(all=TRUE), file = "inData_combine_sim_and_obs_v2_newPlotOrder.RData")
## load("inData_combine_sim_and_obs_v2_newPlotOrder.RData")

# what to do? ----
getObsData = FALSE
getSimData = FALSE
plotDataE = FALSE # Westerland, Waldhof and Zingst; Na+
plotType = 2 # 1 == lines/steps; 2 == points; 
doStatistics = FALSE
doCorr = FALSE
writeOutData = FALSE

if (setup %in% c('effectSeaSalt.v5', 'effectSeaSalt')) { myAero = 'aero5'
} else if (setup %in% c('seasalt3d')) { myAero = 'aero6'
} else { myAero = 'error'}

## AERO5
ssSO4Mass = 0.0755
ssNaMass = 0.3856
ssRealNa2Cat = 0.7800
ssClMass = 0.5389
ssNa2SO4 = ssSO4Mass / ssNaMass / ssRealNa2Cat

# functions and constant ----
myMolMass = list('NO' = 30,'NO2' = 46, 'HNO3' = 63,
                 'ANO3I' = 62, 'ANO3J' = 62, 'ANO3K' = 62,
                 'NH3' = 17, 'ANH4I'= 18, 'ANH4J' = 18, 'ANH4K' = 18,
                 'N' = 15,
                 'ASO4I' = 96, 'ASO4J' = 96, 'ASO4K' = 96, 'SO2' = 64, 'S' = 32)
R = 8.314462
modeConvA = list('I' = 'ATKN', 'J' = 'ACC', 'K' = 'COR')
modeConvB = list('ATKN' = 'I', 'ACC' = 'J', 'COR' = 'K')

# directories and files ----
inDir = '/storage/neumannd/data/cctm/CD24/analysis'
fracDir = './31_AOD_C_Volker/data'

# parameters ----
MONs = c('win2008', 'sum2008')
SPECs = c('SNH4', 'SNO3', 'Na', 'SO4', 'XSO4')
MATRICES = list('SNH4'='air+aerosol', 'SNO3'='air+aerosol', 'SO4'='aerosol', 'XSO4'='aerosol', 'Na'='aerosol', 'SNH4'='aerosol', 'SNO3'='aerosol')
UNITS = list('SNH4'='ug N/m3', 'SNO3'='ug N/m3', 'SO4'='ug S/m3', 'XSO4'='ug S/m3', 'Na'='ug/m3', 'NH4'='ug N/m3', 'NO3'='ug N/m3')
SCENs = c('base', 'sp13.corr', 'ov14.corr', 'zero')
nSTATION=-1


if (getSimData) {
  valSIM = list(); nCOL=-1; nROW=-1;
  for(iMon in MONs) {
    valSIM[[iMon]] = list()
    for(iScen in SCENs) {
      valSIM[[iMon]][[iScen]] = list()
    }
  }
  
  PMfrac = list()
  fltFRACs = c(10, 2.5, 1.0, 0.5, 0.1, 0.05)
  strFRACs = sub('.', 'p', formatC(fltFRACs, format = 'f', width = 6, digits = 3, flag = "0"), fixed = TRUE)
  ncId = nc_open(paste(fracDir, 'PM_fractions_v01.nc', sep = '/'))
  for (iF in strFRACs) {
    PMfrac[[iF]] = ncvar_get(ncId, paste('PM', iF, 'frac', sep = ''))
  }
  nc_close(ncId)
}


# get data ----
for(iMon in MONs) {
  #' for case effectSeaSalt.v5
  if(iMon == 'sum2008' || iMon == 'sum') {
    nT = 61; from = 2008183; to = 2008243
  } else if(iMon == 'win2008' || iMon == 'win') {
    nT = 60; from = 2008001; to = 2008060
  }
  nTh = nT * 24

  # myStations = stations[-c(11, 12, 13, 14, 16, 17, 18, 19, 25)]
  myStations = c("DE0001R", "DE0002R", "DE0009R")
  nSTATIONS=length(myStations)
  
  if(getObsData && setup != 'seasalt3d') {
    print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
    print('READING OBSERVATIONAL DATA FROM DATABASE')
    print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
    for (iSpec in c('NO3', 'NH4')) {
      valOBS[[iMon]][[iSpec]] = list()
    # for (iSpec in SPECs) {
      tmpOBS <- getobservationts(from,to,iSpec, stations = myStations, matrix=MATRICES[[iSpec]], vlevel = gsub('or', 'and', gsub(', 781,', ',', vlevel(1))))
      
      if (MATRICES[[iSpec]] == 'aerosol' && iSpec %in% c('Na', 'SO4')) tmpOBS$DE0044R = getobservationts(from,to,iSpec, stations = 'DE0044R', matrix='pm10', vlevel = gsub('or', 'and', gsub(', 781,', ',', vlevel(1))))
      if (iSpec == 'XSO4') tmpOBS[['DE0044R']] = valOBS[[iMon]][['SO4']][['DE0044R']] - valOBS[[iMon]][['Na']][['DE0044R']] * 0.077/0.306/3
      
      for(iStat in c('FI0009R', 'FI0017R')) {
        tmpOBS[[iStat]] = myObs[[iStat]][[iSpec]]
        tmpOBS[[iStat]]$timeser$n = tmpOBS[[iStat]]$timeser$n[(from-2008000):(to-2008000)]
        tmpOBS[[iStat]]$timeser$values = tmpOBS[[iStat]]$timeser$values[(from-2008000):(to-2008000)]
        tmpOBS[[iStat]]$timeser$time = tmpOBS[[iStat]]$timeser$time[(from-2008000):(to-2008000)]
      }
      
      iStat = 'NL0011R'
      tmpOBS[[iStat]] = myObs[[iStat]][[iSpec]]
      tmpOBS[[iStat]]$timeser$n = tmpOBS[[iStat]]$timeser$n[((from-2008000-1)*24+1):((to-2008000)*24)]
      tmpOBS[[iStat]]$timeser$values = tmpOBS[[iStat]]$timeser$values[((from-2008000-1)*24+1):((to-2008000)*24)]
      tmpOBS[[iStat]]$timeser$time = tmpOBS[[iStat]]$timeser$time[((from-2008000-1)*24+1):((to-2008000)*24)]
      
      for (iStat in myStations) {
        tmpVals = tmpOBS[[iStat]]$timeser$values
        tmpVals[tmpVals > 10] = NaN
        tmpOBS[[iStat]]$timeser$values = tmpVals
      }
      
      for (iStat in myStations) {
        valOBS[[iMon]][[iSpec]][[iStat]] = tmpOBS[[iStat]]
      }
    }
    
    myPositions = list()
    myCells = list()
    
    for(iPos in myStations) {
      myPositions[[iPos]] = list('lat' = valOBS[[iMon]][['SO4']][[iPos]]$station$latitude,
                                 'lon' = valOBS[[iMon]][['SO4']][[iPos]]$station$longitude)
      myCells[[iPos]] = findcell(myPositions[[iPos]], CD24)
    }
  }


  if(getSimData) {
    myStart = rep(1, 4)
    myCount = c(-1, -1, 1, nTh)
    myIndices = array(c(rep(t(array(unlist(myCells), dim = c(2,nSTATIONS))),each=nTh),rep(1:nTh, nSTATIONS)), dim = c(nTh*nSTATIONS,3))
    
    print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
    print('READING SIMULATION DATA FROM NETCDF FILES')
    print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
    print(paste('~~ Season:', iMon))
    print('  READING MET FILE')
    # get data: meteorology ----
    ncMet <- nc_open(paste(inDir, paste('METCRO3D', iMon, sep = '.'), sep = '/'))
    
    valPRES = matrix(ncvar_get(ncMet, 'PRES', start = myStart, count = myCount)[myIndices], ncol=nSTATIONS)
    valTA   = matrix(ncvar_get(ncMet, 'TA', start = myStart, count = myCount)[myIndices], ncol=nSTATIONS)
    
    nc_close(ncMet)
    
    for(iScen in SCENs) {
      print(paste('~~ Scenario:', iScen))
      
      # get data: aerosol ----
      print(paste('  READING AERODIAM files for scenario ', iScen, sep = ''))
      ncId = nc_open(paste(inDir, paste('BL_AERODIAM.CD24_', setup, '.', iScen,
                                        '_', mech, '_', iMon, '.short', sep = ''), 
                           sep = '/'))
      
      for (iV in c('DG', 'STDEV', 'PM25')) {
        valSIM[[iMon]][[iScen]][[iV]] = list()
        for (iM in c('ATKN', 'ACC', 'COR')) {
          valSIM[[iMon]][[iScen]][[iV]][[iM]] = matrix(ncvar_get(ncId, paste(iV, if(iV=='PM25') substr(iM,1,2) else iM , if(iV=='DG') '_DRY' else '', sep = ''), start = myStart, count = myCount)[myIndices], ncol=nSTATIONS)
        }
      }
      
      for (iF in strFRACs) {
        myFRAC = paste('PM', iF, sep = '')
        valSIM[[iMon]][[iScen]][[myFRAC]] = list()
        for (iM in c('ATKN', 'ACC', 'COR')) {
          tmpGMDs = valSIM[[iMon]][[iScen]][['DG']][[iM]]
          tmpSIGs = valSIM[[iMon]][[iScen]][['STDEV']][[iM]]
          idxGMDs = rep(0.0, prod(dim(tmpGMDs))); idxGMDs[] = pmin(pmax(round(tmpGMDs[]*1000), 1),3500)
          idxSIGs = rep(0.0, prod(dim(tmpSIGs))); idxSIGs[] = pmax(round((tmpSIGs[]-1)*1000), 1)
          tmpPMfrac = PMfrac[[iF]][cbind(idxGMDs, idxSIGs)]
          dim(tmpPMfrac) = dim(tmpGMDs)
          valSIM[[iMon]][[iScen]][[myFRAC]][[iM]] = tmpPMfrac
        }
      }
      
      
      # get data: concentrations ----
      print(paste('  READING CONC files for scenario ', iScen, sep = ''))
      ncId = nc_open(paste(inDir, paste('BL_CONC.CD24_', setup, '.', iScen,
                                        '_', mech, '_', iMon, '.short', sep = ''), 
                           sep = '/'))
      
      print('    Reading Gas Phase Species')
      for (iSpec in c('NH3', 'HNO3')) { # only for gas phase N species
        valSIM[[iMon]][[iScen]][[iSpec]] = ( matrix(ncvar_get(ncId, iSpec, start = myStart, count = myCount)[myIndices], ncol=nSTATIONS) 
                                        * valPRES / valTA / R * myMolMass$N )
      }
    
      print('    Reading Particle Phase Species')
      #' Initialize data arrays. Six rows below we will sum some variables in
      #' a for loop by adding a newly read variable to an existing variable. 
      #' The 'existing' variables are initialised here with the correct size.
      SUBs = c('NH4', 'NO3', 'SO4', 'Na')
      for (iSub in SUBs) {
        valSIM[[iMon]][[iScen]][[iSub]] = array(0.0, dim = dim(valPRES))
      }
      
      for (iMode in c('I', 'J', 'K')) {
        # The tmpPMfrac variable scales from TSP to PM10.
        tmpPMfrac = valSIM[[iMon]][[iScen]][['PM10p000']][[modeConvA[[iMode]]]]
        # tmpPMfrac = 1
        for(iSub in SUBs) { # without I, J and K ending
          # set the name of the aerosol species in the input file
          varName = paste('A', toupper(iSub), iMode, sep = '')
          #' set a scaling factor by which the variables' values are scaled:
          #'  - nitrogen and sulfur compounds: we want the mass in 
          #'      'mass N per ...' and 'mass S per ...' and not the mass
          #'      in 'mass NO3- per ...'.
          #'  - sea salt is considered differently (see if clause six rows
          #'      below)
          varFac = myMolMass[[substr(iSub, 1,1)]] / myMolMass[[varName]]
          
          if(iSub == 'Na') {
            # model sea salt sodium represents all sea salt cations
            varFac = ssRealNa2Cat 
            if (myAero == 'aero6') {
              # ANAJ is denoted as ASEACAT to avoid ambiguity
              if (iMode == 'K') varName = 'ASEACAT' 
              # all sea salt sodium in ANAJ is actual sea salt sodium (and not e.g. magnesium)
              if (iMode == 'J') varFac = 1 
            }
          }
          
          if (!( (!(iScen%in%c('sp13.corr','sp13.noSu','ov14.corr','ov13.bndy'))) && varName == 'ANAI') ) {
            # Do always into this if except we are in base and zero case AND 
            # our varName equals ANAI. We have no ANAI variable in the base
            # and zero case (but in sp13 and ov14 we have them).
            valSIM[[iMon]][[iScen]][[iSub]] =
              ( valSIM[[iMon]][[iScen]][[iSub]] +
                varFac * tmpPMfrac * matrix(ncvar_get(ncId, varName, start = myStart, count = myCount)[myIndices], ncol=nSTATIONS)
              )
          }
        }
      }
      
      print('    Calculating derived variables')
      valSIM[[iMon]][[iScen]]$SNH4 = valSIM[[iMon]][[iScen]]$NH3 + valSIM[[iMon]][[iScen]]$NH4
      valSIM[[iMon]][[iScen]]$SNO3 = valSIM[[iMon]][[iScen]]$HNO3 + valSIM[[iMon]][[iScen]]$NO3
      valSIM[[iMon]][[iScen]]$XSO4 = valSIM[[iMon]][[iScen]]$SO4 - valSIM[[iMon]][[iScen]]$Na * ssNa2SO4 / 3
      
      nc_close(ncId)
    }
  }
}

gc()

# plot dataE ----
if(plotDataE) {  
  # plot dataE: define output file type ----
  ## axis labels
  yAxisLab = list('SNH4' = expression("NH"[4]^"+" ~ "+" ~ "NH"[3] ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g N/' * m^3 * ']'),
                  'SNO3' = expression("NO"[3]^"-" ~ "+" ~ "HNO"[3] ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g N/' * m^3 * ']'),
                  'SO4' = expression("SO4"[4]^"2-" ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g S/' * m^3 * ']'),
                  'Na' = expression("Na"^"+" ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g/' * m^3 * ']'),
                  'XSO4' = expression("corr. SO4"[4]^"2-" ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g S/' * m^3 * ']'),
                  'NH4' = expression("NH"[4]^"+" ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g N/' * m^3 * ']'),
                  'NO3' = expression("NO"[3]^"-" ~ ' PM'[10] ~ 'concentration [' ~ mu * 'g N/' * m^3 * ']'))
  ## species to consider:
  iSpec = 'Na'
  
  ## create output file (pdf)
  pdf(file = paste('fig09_CONC.timeseries', setup, iSpec, 'threeStations.newer', 'pdf', sep = '.'), onefile=TRUE,
            paper = 'special', width = 10, height = 6.5)
  
  ## set plot parameters
  par(mar = c(0,0,0,0)+0, mgp = c(1.5,0.5,0.0))
  
  # plot dataE: define screens ----
  ShlB = 0.07 # left
  ShrB = 0.992 # right
  ShdB = 0.035 # Abstand
  SvtB = 0.93 # top
  SvbB = 0.05 # bottom
  SvdB = 0.01 # Abstand
  ShBox = 0.06
  
  ShcB = ShlB+(ShrB-ShlB)*3/6 # center
  ShwB = ShrB-ShlB # width
  
  iScreen = 0
  
  for(iLoc in 1:3){
    ## get some statione information
    iStat = myStations[iLoc]
    myLoc = myCells[[iStat]]
    
    ## divide page into screens and plot legend
    if(iScreen%%13 == 0) {
      if(iScreen != 0) plot.new()
      iScreen = 1
      
      split.screen(rbind(c(ShlB,ShrB, SvtB+SvdB, 1.0-SvdB), # legend row
                         # top left, time series
                         c(ShlB, ShcB-ShdB/2-ShBox, SvbB+(SvtB-SvbB)*2/3+SvdB/2, SvtB),
                         c(ShcB-ShdB/2-ShBox, ShcB-ShdB/2, SvbB+(SvtB-SvbB)*2/3+SvdB/2, SvtB),
                         # top right, time series
                         c(ShcB+ShdB/2, ShrB-ShBox, SvbB+(SvtB-SvbB)*2/3+SvdB/2, SvtB),
                         c(ShrB-ShBox, ShrB, SvbB+(SvtB-SvbB)*2/3+SvdB/2, SvtB),
                         # center left, time series
                         c(ShlB,ShcB-ShdB/2-ShBox, SvbB+(SvtB-SvbB)*1/3+SvdB/2, SvbB+(SvtB-SvbB)*2/3-SvdB/2),
                         c(ShcB-ShdB/2-ShBox, ShcB-ShdB/2, SvbB+(SvtB-SvbB)*1/3+SvdB/2, SvbB+(SvtB-SvbB)*2/3-SvdB/2),
                         # center right, time series
                         c(ShcB+ShdB/2, ShrB-ShBox, SvbB+(SvtB-SvbB)*1/3+SvdB/2, SvbB+(SvtB-SvbB)*2/3-SvdB/2),
                         c(ShrB-ShBox, ShrB, SvbB+(SvtB-SvbB)*1/3+SvdB/2, SvbB+(SvtB-SvbB)*2/3-SvdB/2),
                         # bottom left, time series
                         c(ShlB,ShcB-ShdB/2-ShBox, SvbB, SvbB+(SvtB-SvbB)*1/3-SvdB/2),
                         c(ShcB-ShdB/2-ShBox, ShcB-ShdB/2, SvbB, SvbB+(SvtB-SvbB)*1/3-SvdB/2),
                         # bottom right, time series
                         c(ShcB+ShdB/2, ShrB-ShBox, SvbB, SvbB+(SvtB-SvbB)*1/3-SvdB/2),
                         c(ShrB-ShBox, ShrB, SvbB, SvbB+(SvtB-SvbB)*1/3-SvdB/2)
      ))
      
      # plot dataE: make legend ----
      ## plot legend into screen 1
      screen(iScreen)
      
      ## we do a trick here: create an empty plot and put a legend into it
      plot(c(0,1), c(0,1), xaxt = 'n', yaxt = 'n', ann = FALSE, type = 'n')
      
      legend('left', legend = c(expression('OBS, PM'[10]), 'GO03', 'SP13', 'OV14', '', '  year 2008'),
             col = c('darkgrey', 'cyan', 'orange', 'darkviolet', 'white', 'white'),
             lwd = c(10,2,2,2,2, NA), 
             lty = NA, pch = c(15, 19, 1, 8, 4, NA),
             bg = 'white', horiz = TRUE, inset = 0.02,
             pt.cex = 2, seg.len = 0.5, text.width = 0.15, bty = 'n')
      legend('left', legend = c('OBS', '', '', '', '', ''),
             col = 'black', lwd = 2,  pch = NA,
             lty = c('solid',NA,NA,NA,NA,NA),
             bg = 'white', horiz = TRUE, inset = 0.02,
             pt.cex = 2, seg.len = 0.5, text.width = 0.15, bty = 'n')
    }
    
    
    ## some y-max calculations
    myMax = 0
    for (iMon in MONs) {
      myMax = max(myMax, max(valOBS[[iMon]][[iSpec]][[iStat]]$timeser$value, na.rm = TRUE))
      for(iScen in SCENs) {
        myMax = max(myMax, max(make_daily_mean(valSIM[[iMon]][[iScen]][[iSpec]][,iLoc]), na.rm = TRUE))
      }
    }
    myLim = getYlim(myMax, 3)
    
    ## start and stop days depending on considered season
    for(iMon in MONs) {
      refDate=2008001
      strYear='2008'
      if(iMon == 'sum2008' || iMon == 'sum') {
        nT = 61
        from = 2008183
        to = 2008243
      } else if(iMon == 'win2008' || iMon == 'win') {
        nT = 60
        from = 2008001
        to = 2008060
      }
      
      # plot dataE: prepare data ----
      timeAxis = as.POSIXct((0:(nT) + (from-refDate))*3600*24, tz = 'UTC', origin = "2008-01-01 00:00:00")
      
      pltOBS = rep(0.0, nT)
      pltOBS = valOBS[[iMon]][[iSpec]][[iStat]]$timeser$value
      if ( is.null(pltOBS) ||
           length(pltOBS) == 0) {
        pltOBS = rep(0.0, nT)
      }
      
      pltOBSnoNA = pltOBS
      pltOBSnoNA[is.na(pltOBS)] = 0
      
      # alternative: colMeans(array(ARRAY, dim = c(24,91)), na.rm = TRUE)
      pltSIMbase = make_daily_mean(valSIM[[iMon]][['base']][[iSpec]][1:(nT*24),iLoc])
      pltSIMsp13b = make_daily_mean(valSIM[[iMon]][['sp13.corr']][[iSpec]][1:(nT*24),iLoc])
      pltSIMov13m = make_daily_mean(valSIM[[iMon]][['ov14.corr']][[iSpec]][1:(nT*24),iLoc])
      pltSIMzero = make_daily_mean(valSIM[[iMon]][['zero']][[iSpec]][1:(nT*24),iLoc])
      
      myMax = max(c(max(pltOBS, na.rm = TRUE), 
                    max(pltSIMbase),
                    #                       max(pltSIMsp13b),
                    max(pltSIMov13m)), na.rm = TRUE)
      myLim = getYlim(myMax, 3)
      
      # plot dataE: start plotting ----
      iScreen = iScreen + 1 
      #         x11()
      
      ## ACTUAL PLOTTING START
      ## activate screen for the left hand side time series
      screen(iScreen)
      ## create empty basic plot
      plot(timeAxis[-nT-1], pltOBSnoNA,
           type = 'n', ann = FALSE, ylim = c(0,myLim),
           yaxt = 'n', xaxt = 'n')
      
      if ((iScreen-1)%%2 == 1) axis(2)
      
      ## add axes and labels
      yTicksWin = c(1199145600, 1201824000, 1204329600, 1207008000)
      yTicksSum = c(1215043200, 1217721600, 1220400000, 1222992000)
      if(iScreen %in% c(2, 6, 10)) axis(1,at = yTicksWin, labels = FALSE, tck = -0.03)
      if(iScreen == 10) axis(1,at = (yTicksWin[-1]+yTicksWin[-4])/2, tick = FALSE, labels = c('Jan', 'Feb', 'Mar'))
      if(iScreen %in% c(4, 8, 12)) axis(1,at = yTicksSum, labels = FALSE, tck = -0.03) # 1212278400, 1214870400, 1217548800, 1220227200
      if(iScreen == 12) axis(1,at = (yTicksSum[-1]+yTicksSum[-4])/2, tick = FALSE, labels = c('Jul', 'Aug', 'Sept'))
      if(iScreen == 6) mtext(yAxisLab[[iSpec]],2, line = 1.6)
      if ((iScreen-1)%%4 == 3) title(valOBS[[1]][[1]][[iStat]]$station$station_name, line = -1)
      
      ## grey bars
      polygon(rep(timeAxis, each = 2), append(append(rep(pltOBSnoNA, each = 2), 0, after = 0), 0),
              col = 'darkgrey', border = FALSE)
      
      ## colored symbols
      points(colMeans(rbind(timeAxis[-1],timeAxis[-nT-1])), pltSIMbase,
             col = 'cyan', pch = 19, cex = 0.8)
      points(colMeans(rbind(timeAxis[-1],timeAxis[-nT-1])), pltSIMsp13b,
             col = 'orange', pch = 1, cex = 0.8)
      points(colMeans(rbind(timeAxis[-1],timeAxis[-nT-1])), pltSIMov13m,
             col = 'darkviolet', pch = 8, cex = 0.8)
      
      ## activate screen for the right hand side box plot
      iScreen = iScreen + 1 
      screen(iScreen)
      # NOTE: [,!is.na(pltOBS)] makes that only values are considered which
      #       are available as observations and measurements.
      boxplot(apply(rbind(pltOBS, pltSIMbase, pltSIMsp13b, pltSIMov13m)[,!is.na(pltOBS)], MARGIN = 1, FUN = quantile, probs = c(0, 0.25, 0.5, 0.75, 1.0), na.rm = TRUE),
              yaxt = 'n', xaxt = 'n', xlab = '', ylab = '', ylim = c(0,myLim), border = c('black', 'cyan', 'orange', 'darkviolet'), range = 0)
      points(1:4, apply(rbind(pltOBS, pltSIMbase, pltSIMsp13b, pltSIMov13m), MARGIN = 1, FUN = mean, na.rm = TRUE),
             pch = 18, col = c('black', 'cyan', 'orange', 'darkviolet'))
      
      ## ACTUAL PLOTTING END
    }
  }
  close.screen(all.screens = TRUE)
  dev.off()
  
}
