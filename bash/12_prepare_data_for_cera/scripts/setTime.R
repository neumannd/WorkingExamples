#!/bin/Rscript

#' setTime
#' 
library('ncdf4')
source('./getSecondsSince1900fromJulian.R')

# set diagnostic parameters ----
batchmode=TRUE
DATE = 2012001
INFILE = '/media/neumannd/media_mn/cctm/out/step02b.nc'
OUTFILE =  '/media/neumannd/media_mn/cctm/out/step02c.nc'


# get arguments ----
if(batchmode) {
  args = commandArgs(trailingOnly = TRUE)
} else {
  args = c(DATE, INFILE, OUTFILE)
}
nArgs = length(args)

# look whether help was requested ----
if (length(args) == 0) {
  cat("No arguments parsed. Please call './setTime -h' for help.\n")
} else if (args[1] == '-h') { ## HELP
  cat(paste("HELP for setTime.R::\n  'setTime JULIAN_DATE INFILE OUTFILE'\n",
            "    JULIAN_DATE: julian date in the format YYYYDDD\n", 
            "    INFILE:      input file (netCDF file)\n", 
            "    OUTFILE:     output file (netCDF file)\n\n",
            "  If INFILE should be modified and OUTFILE not create please set OUTFILE = INFILE. The old file will not be overwritten but modified.\n",
            sep = ''))
  
# if no help was requested ----
} else { ## NO HELP
  
  # 
  if(nArgs != 3) {
    
    tmpText = paste(formatC(nArgs, format = 'd'), ' instead of 3 arguments provided. ', sep = '')
    if (nArgs == 3) {
      tmpText = paste(tmpText, 'If INFILE should be modified and no OUTFILE created please set OUTFILE = INFILE. ', sep = '')
    }
    tmpText = paste(tmpText, 'Please type -h for help. ', sep = '')
  }
  
  julianDateInt = as.integer(args[1])
  
  if (args[2] != args[3]) {
    file.copy(args[2], args[3])
  }
  modFile = args[3]
  
  ncId = nc_open(modFile, write = TRUE)
  
  nTimes = ncId$dim$time$len
  if (nTimes%in%c(1,24)) { ## FINE
    
    ncatt_put(ncId, 'time', 'units', 'seconds since 1900-01-01 00:00:00.0 UTC')
    ncatt_put(ncId, 'time_bnds', 'units', 'seconds since 1900-01-01 00:00:00.0 UTC')
    
    time = ncvar_get(ncId, 'time')
    time_bnds = array(ncvar_get(ncId, 'time_bnds'), dim = c(2,nTimes))
    
    for (iHour in 0:(nTimes-1)) {
      tmpSec1 = getSecondsSince1990fromJulian(julianDateInt, iHour)
      tmpSec2 = getSecondsSince1990fromJulian(julianDateInt, iHour + 24/nTimes)
      time[iHour+1] = (tmpSec1 + tmpSec2)/2
      time_bnds[, iHour+1] = c(tmpSec1, tmpSec2)
    }
    ncvar_put(ncId, 'time', time)
    ncvar_put(ncId, 'time_bnds', time_bnds)
    
    nc_close(ncId)
    
  } else { ## NOT FINE: incompatible number of time steps
    
    nc_close(ncId)
    
    stop(paste("Number of time steps should be 1 or 24 (and time dimension should be 'time') but it is ", formatC(nTimes, format = 'd'), sep = ''))
    
  }
  
} ## HELP