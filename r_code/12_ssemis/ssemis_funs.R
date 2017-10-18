#' ssemis_funs
#' 
#' This script is part of a sea salt emissions calculation programme. The programme
#' calculates sea salt emissions according to the sea salt emission function by 
#' Ovadnevaite et al. (2014) and Spada et al. (2013). This script provides functions
#' needed by the main routine.
#' 
#' @author Daniel Neumann
#' @date 2015-Nov-06
#' @version 4.0.1
#' Version description: Same functions as version 3.0.0. Optimised programme
#'  structure by reduction of for loops and compiled functions. Since version
#'  3.6.0 some more functions were compiled and shortened. Since version 3.6.5 
#'  emissions of Gong2003 were added. In version 3.9.0 the versioning procedure
#'  and some internal naming conventions were changed. OV14 was accidently 
#'  denoted as OV13 in earlier versions. It was correct in v3.9.0. Version 
#'  4.0.0 removes much things which were set to deprecated in v3.9.0 and 
#'  finalizes the corrections from OV13 to OV14.


#' load libraries and functions ----
library('compiler')
library('ncdf4')
source('ssemis_params.R')
source('ssemis_versioning.R')


# general functions ----

#' TODO: documentation
#' @param 
#' @return 
get_relativehumidity_a = function(date, grid, namespace) {
  #' initialise array for output data
  outRH = array(0.0, dim = c(grid$ncol, grid$nrow, 25))
  
  ncIdRH = nc_open(namespace$MC3D$path)
  
  #' Test whether the data in the input file are on the correct grid.
  if ( ncIdRH$dim$COL$len != grid$ncol || ncIdRH$dim$ROW$len != grid$nrow ) {
    warning(paste('Horizontal dimensions in met file and chosen grid are not equal. ',
                  'File grid: ', ncIdRH$dim$COL$len, " x ", ncIdRH$dim$ROW$len, 
                  '; our grid: ', grid$ncol, ' x ', grid$nrow, sep = ""))
  }

  # read data and calculate RH
  tmpTK <- ncvar_get(ncIdRH, "TA", start=c(1, 1, 1, 1), count=c(-1, -1, 1, -1))
  tmpRho <- ncvar_get(ncIdRH, "DENS", start=c(1, 1, 1, 1), count=c(-1, -1, 1, -1))
  tmpQV <- ncvar_get(ncIdRH, "QV", start=c(1, 1, 1, 1), count=c(-1, -1, 1, -1)) 
  tmpTC = tmpTK - 273.3
# temperature in C needed
  p_max <- 611.2 * exp(17.62 * tmpTC / (243.12 + tmpTC))
# temperature in C needed
  p <- tmpQV * tmpRho / (1 + tmpQV) * R / M_H2O * tmpTK * 10^3
  outRH <- p / p_max

  #' close the input file
  nc_close(ncIdRH)
  
  #' return input data
  return(outRH)
}




# TODO: documentation
get_griddesc = function(gridname) {
  GRID_NAME = toupper(gridname)
  
  griddef = list('ncol' = 0, 'nrow' = 0,
                 'E0' = 0, 'N0' = 0,
                 'xcell' = as.integer(substr(gridname, 3, 4)),
                 'ycell' = as.integer(substr(gridname, 3, 4)),
                 'cen' = list('lat' = 55, 'lon' = 10),
                 'sp' = c(30,60),
                 'name' = gridname)
  
  if(GRID_NAME == 'CD06') {griddef$ncol=160; griddef$nrow=157; griddef$E0=672; griddef$N0=537}
  else if (GRID_NAME == 'CD24') {griddef$ncol=112; griddef$nrow=106; griddef$E0=1398; griddef$N0=1191}
  else if (GRID_NAME == 'CD72') {griddef$ncol=57; griddef$nrow=66; griddef$E0=1926; griddef$N0=2655}
  else if (GRID_NAME == 'AQ24') {griddef$ncol=171; griddef$nrow=198; griddef$E0=1926; griddef$N0=2655}
  else {griddef$ncol=1; griddef$nrow=1; griddef$E0=0; griddef$N0=0}
  
  return(griddef)
}



#'
#'
#' TODO: documentation
calc_rh_index_ = function(rh) {
  c1 = (rh <= 0.45)
  c2 = as.logical((rh > 0.45)*(rh <= 0.9))
  c3 = as.logical((rh > 0.90)*(rh <= 0.99))
  c4 = (rh > 0.99)
  
  # index
  idx = rep(0.0, length(rh))
  idx[c1] = 1
  idx[c2] = floor(100 * rh[c2] + 0.001 - 44.0)
  idx[c3] = floor(1000 * rh[c3] + 0.001 - 854.0)
  idx[c4] = 136
  # idx = as.integer(idx)
  
  # ratio
  c2 = as.logical((rh > 0.45)*(rh <= 0.9)*(idx < 46))
  c3 = as.logical((idx > 45)*(idx < 136))
  c4 = (idx == 136)
  
  rti = rep(0.0, length(rh))
  rti[c1] = 1
  rti[c2] = 1 - (rh[c2] - (idx[c2] + 44) / 100) * 100
  rti[c3] = 1 - (rh[c3] - (idx[c3] + 854) / 1000) * 1000
  rti[c4] = 1
  
  return(list('index'=idx,'ratio'=rti))
}

# TODO: documentation
calc_rh_index = cmpfun(calc_rh_index_)


# TODO: documentation
size_scale_rh_ = function(rh) {
  c1 = (rh < 0.45)
  c2 = as.logical((rh >= 0.45) * (rh <= 0.99))
  c3 = (rh > 0.99)
  
  if (length(dim(rh)) == 0) dim(rh) = length(rh)
  
  valOut = array(0.0, dim = dim(rh))
  valOut[c1] = 1.525504
  valOut[c2] = 1.08 * ((2-rh[c2])/(1-rh[c2]))^(1/3)
  valOut[c3] = 5.02957
  
  return(valOut)
}

# TODO: documentation
size_scale_rh = cmpfun(size_scale_rh_)


# TODO: documentation
split_ssemis = function(bulkSSEMIS, 
                        unitSSEMIS = "micrograms/m**3 ",
                        mySplit = CMAQmy_split, 
                        mySpecs = CMAQmy_specs,
                        myModes = CMAQmy_modes) {
  
  if(typeof(unitSSEMIS) == 'character') {
    tmpUnit = unitSSEMIS
    unitSSEMIS = list('DRY'=list('I'=tmpUnit,'J'=tmpUnit,'K'=tmpUnit),
              'WET'=list('I'=tmpUnit,'J'=tmpUnit,'K'=tmpUnit))
  }
  
  nModes = length(myModes)
  nSpecies = length(mySpecs)
  
  #' apply split and put everything into a list
  speciatedSSEMIS = list()
  speciatedSSEMIS[['SSEMIS']] = list()
  speciatedSSEMIS[['UNITS']] = list()
  
  for (iM in 1:nModes) {
    for (iS in 1:nSpecies) {
      if (mySplit[iS, iM] != -1) {
        if (mySpecs[iS] == 'SEACAT') {
          varName = paste('A', mySpecs[iS], sep = "")
        } else {
          varName = paste('A', mySpecs[iS], myModes[iM], sep = "")
        }
        # NEUMANND PARTIKELWASSER
        speciatedSSEMIS$SSEMIS[[varName]] = bulkSSEMIS$DRY[[myModes[iM]]] * mySplit[iS, iM]
        speciatedSSEMIS$UNITS[[varName]] = unitSSEMIS$DRY[[myModes[iM]]]
      }
    }
    
    varName = paste('AH2O', myModes[iM], sep = "")
    speciatedSSEMIS$SSEMIS[[varName]] = bulkSSEMIS$WET[[myModes[iM]]] - bulkSSEMIS$DRY[[myModes[iM]]]
    speciatedSSEMIS$UNITS[[varName]] = unitSSEMIS$WET[[myModes[iM]]]
  }
  
  #' return the list
  return(speciatedSSEMIS)
}


#' TODO: documentation
write_ssemis = function(grid, date, namespace, COORDS, SSEMIS, UNITS) {
  #' Convert integer date into string
  #' not needed in the moment
  strDate0 = formatC(date, format='d', width = 7)
  strDate1 = formatC(date+1, format='d', width = 7)
  intYear = floor(date / 1000)
  intDay = date - intYear * 10^3
  strYear = formatC(intYear, format='d', width = 4)
  
  #' get number of variables
  nVars = length(names(SSEMIS))
  myVarList = paste(formatC(names(SSEMIS), width = -16), sep = "", collapse = "")
  
  #' create file name
#   pathOut = paste(namespace$dOut, '/', namespace$fOut, '_', grid$name, '_', strDate0, sep = "")
  pathOut = namespace$OUT$path
  
  
  #' construct dimensions
  dimTSTEP <- ncdim_def('TSTEP', 
                        units = "",
                        vals = 1:25,
                        unlim = TRUE,
                        create_dimvar = FALSE
  )
  dimVAR <- ncdim_def('VAR', 
                      units = "",
                      vals = 1:as.integer(nVars),
                      create_dimvar = FALSE
  )
  dimDT <- ncdim_def('DATE-TIME', 
                     units = "",
                     vals = 1:2,
                     create_dimvar = FALSE
  )
  dimLAY <- ncdim_def('LAY', 
                      units = "",
                      vals = 1:1, 
                      create_dimvar = FALSE
  )
  dimROW <- ncdim_def('ROW', 
                      units = "",
                      vals = 1:(grid$nrow), 
                      create_dimvar = FALSE
  )
  dimCOL <- ncdim_def('COL', 
                      units = "",
                      vals = 1:(grid$ncol), 
                      create_dimvar = FALSE
  )
  
  
  #' construct variables
  varDefs = list()
  varDefs$varTFLAG <- ncvar_def( 'TFLAG', '<YYYYDDD,HHMMSS>', 
                                 list(dimDT, dimVAR, dimTSTEP), 
                                 longname = 'TFLAG           ', 
                                 prec = 'integer' )
  for( iV in 1:nVars) {
    myName = names(SSEMIS)[iV]
    varDefs[[myName]] <- ncvar_def( myName, formatC(UNITS[[myName]], width = -16), 
                                    list(dimCOL, dimROW, dimLAY, dimTSTEP), 
                                    longname = formatC(myName, width = -16), 
                                    prec = 'float' )
  }
  
  
  #' create file
  ncIdNew <- nc_create( pathOut, varDefs )  
  
  #' add variable attributes
  ncatt_put(ncIdNew, varid='TFLAG', attname='var_desc', 
            attval='Timestep-valid flags:  (1) YYYYDDD or (2) HHMMSS                                ', 
            prec='text')

  for( iV in 1:nVars) {
    myName = names(SSEMIS)[iV]
    ncatt_put(ncIdNew, varid=myName, attname='var_desc', 
              attval=formatC(paste('hourly', myName, 'sea-salt emission rate', sep = ' '), width = -80), 
              prec='text')
  }
  
  #' add global attributes
  ncatt_put(ncIdNew, varid=0, attname='FTYPE', 
            attval=as.integer(1), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='CDATE', 
            attval=as.integer(format(Sys.time(), format="%Y")) * 10^3 + 1 + julian(Sys.Date(), origin = as.Date(paste(format(Sys.time(), format="%Y"), "-01-01", sep=""))), 
            prec='int')
  ncatt_put(ncIdNew, varid=0, attname='CTIME', 
            attval=as.integer(format(Sys.time(), format="%H%M%S")), 
            prec='int')
  ncatt_put(ncIdNew, varid=0, attname='WDATE', 
            attval=as.integer(format(Sys.time(), format="%Y")) * 10^3 + 1 + julian(Sys.Date(), origin = as.Date(paste(format(Sys.time(), format="%Y"), "-01-01", sep=""))), 
            prec='int')
  ncatt_put(ncIdNew, varid=0, attname='WTIME', 
            attval=as.integer(format(Sys.time(), format="%H%M%S")), 
            prec='int')
  
  ncatt_put(ncIdNew, varid=0, attname='SDATE', attval=as.integer(date), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='STIME', attval=as.integer(0), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='TSTEP', attval=as.integer(10000), prec='int')
  
  ncatt_put(ncIdNew, varid=0, attname='NTHIK', attval=as.integer(1), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='NCOLS', attval=as.integer(grid$ncol), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='NROWS', attval=as.integer(grid$nrow), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='NLAYS', attval=as.integer(1), prec='int')
  
  ncatt_put(ncIdNew, varid=0, attname='NVARS', attval=as.integer(nVars), prec='int')
  
  ncatt_put(ncIdNew, varid=0, attname='GDTYP', attval=as.integer(2), prec='int')
  
  ncatt_put(ncIdNew, varid=0, attname='P_ALP', attval = grid$sp[1], prec='double')
  ncatt_put(ncIdNew, varid=0, attname='P_BET', attval = grid$sp[2], prec='double')
  ncatt_put(ncIdNew, varid=0, attname='P_GAM', attval = grid$cen$lon, prec='double')
  ncatt_put(ncIdNew, varid=0, attname='XCENT', attval = grid$cen$lon, prec='double')
  ncatt_put(ncIdNew, varid=0, attname='YCENT', attval = grid$cen$lat, prec='double')
  ncatt_put(ncIdNew, varid=0, attname='XORIG', attval = -grid$E0*10^3, prec='double')
  ncatt_put(ncIdNew, varid=0, attname='YORIG', attval = -grid$N0*10^3, prec='double')
  ncatt_put(ncIdNew, varid=0, attname='XCELL', attval = grid$xcell*10^3, prec='double')
  ncatt_put(ncIdNew, varid=0, attname='YCELL', attval = grid$ycell*10^3, prec='double')
  
  ncatt_put(ncIdNew, varid=0, attname='VGTYP', attval = as.integer(2), prec='int')
  ncatt_put(ncIdNew, varid=0, attname='VGTOP', attval = 2000.0, prec='float')
  ncatt_put(ncIdNew, varid=0, attname='VGLVLS', attval = c(1.0, 0.994898), prec='float') # TODO: correct?
  ncatt_put(ncIdNew, varid=0, attname='GDNAM', attval = grid$name, prec='text')
  ncatt_put(ncIdNew, varid=0, attname='UPNAM', attval = 'EXTERNAL        ', prec='text') # TODO: more creative?
  ncatt_put(ncIdNew, varid=0, attname='VAR-LIST', 
            attval = myVarList, prec='text')
  ncatt_put(ncIdNew, varid=0, attname='FILEDESC', attval="sea salt emissions", prec='text')
  ncatt_put(ncIdNew, varid=0, attname='HISTORY', 
            attval = paste("Created at HZG KBT by ssemis tools v",
                           ssemis_version, 
                           " and some scripts. Contact: Daniel Neumann, daniel.neumann@hzg.de",
                           sep = ''), 
            prec='text')
  
  #' Synchronise new netCDF file.
  nc_sync(ncIdNew)
  
  
  #' fill variables
  TMPTFLAG = array(0.0, dim = c(2, nVars, 25))
  for(iTFLAG in 0:24) {
    if(iTFLAG == 24) TMPTFLAG[1,,iTFLAG+1]=rep(strDate1, nVars) else TMPTFLAG[1,,iTFLAG+1]=rep(strDate0, nVars)
    TMPTFLAG[2,,iTFLAG+1] = rep(formatC((iTFLAG%%24)*10000, width = 6, format = 'd', flag = 0), nVars)
  }
  ncvar_put(ncIdNew, varid = 'TFLAG', TMPTFLAG, 
            start = rep(1,3), count = dim(TMPTFLAG))
  
  
  for(iV in 1:nVars) {
    myName = names(SSEMIS)[iV]
    ncvar_put(ncIdNew, varid = myName, SSEMIS[[myName]], 
              start = rep(1,4), count = c(grid$ncol, grid$nrow, 1, 25))
  }
  
  
  #' Close new netCDF file.
  nc_close(ncIdNew)
  
}


# TODO: documentation
ssemis_read_args = function(args.raw.flat) {
  if ( length(args.raw.flat) == 0 ) {
    args.valid.names = c()
    args.valid.list = list()
    args.valid.flat = c()
  } else {
    if (args.raw.flat[1] == '--args') args.raw.flat = args.raw.flat[-1]
    
    loc.valid = rep(FALSE, length(args.raw.flat))
    len.raw = length(args.raw.flat)
    
    args.raw.list = strsplit(args.raw.flat, '=')
    for (i1 in 1:len.raw) {
      if (length(args.raw.list[[i1]]) == 2) {
        loc.valid[i1] = TRUE
      } else {
        print(paste('Argument', args.raw.flat[i1], 'was skipped', sep = ' '))
      }
    }
    
    len.valid = sum(loc.valid)
    
    args.valid.flat = args.raw.flat[loc.valid]
    args.valid.names = unlist(args.raw.list[loc.valid])[(1:len.valid)*2-1]
  args.valid.list = list()
  args.valid.list[1:len.valid] = unlist(args.raw.list[loc.valid])[(1:len.valid)*2]
  names(args.valid.list) = args.valid.names
  }
  
  return(list('args.valid.names' = args.valid.names,
              'args.valid.list' = args.valid.list,
              'args.valid.flat' = args.valid.flat))
}
