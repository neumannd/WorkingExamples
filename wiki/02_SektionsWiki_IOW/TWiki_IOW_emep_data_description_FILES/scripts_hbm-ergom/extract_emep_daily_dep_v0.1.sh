#!/bin/bash

# @description Extraxt daily mean values into daily files.
# @author Daniel Neumann, daniel.neumann@io-warnemuende.de
# @date 2017-08-02
# @version 0.1

module load nco cdo netcdf

##############################################################################
#### USER SECTION ############################################################
##############################################################################
## set data directory
dirDatBase="."

dirDatIn="${dirDatBase}/../hbm-ergom/files_annual"

dirDatOt="${dirDatBase}/../hbm-ergom/files_daily_yyyyddd"

# YEAR="2012"
## set the year-time-range below via the first for-do-loop.

##############################################################################
#### END OF USER SECTION #####################################################
##############################################################################


### TESTS01
## Test whether needed software is installed:
## (taken from http://stackoverflow.com/a/677212/4612235)
hash cdo 2>/dev/null || { echo >&2 "I require cdo but it is not installed or loaded.  Aborting."; exit 1; }
hash ncatted 2>/dev/null || { echo >&2 "I require ncatted but it is not installed or loaded.  Aborting."; exit 1; }

## Test whether all directories exist
if [ ! -d ${dirDatIn} ]; then echo >&2 "The input directory ${dirDatIn} does not exist (=dirDatIn). Aborting."; exit 1; fi
if [ ! -d ${dirDatOt} ]; then echo >&2 "The output directory ${dirDatOt} does not exist (=dirDatOt). Aborting."; exit 1; fi


## YEARs
for YEAR in '2012'; do

  ## grids
  for grid_type in 'fine' 'coarse'; do  
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "   do grid ${grid_type}"
    echo "  "
    
    inFile="EMEP_50km_2_${grid_type}_masked_${YEAR}.nc"
    inPath="${dirDatIn}/${grid_type}/${inFile}"
    
    ### TESTS02
    ## Test whether input data exist
    if [ ! -e ${inPath} ]; then echo >&2 "The netCDF input file ${inPath} does not exist (=inPath). Aborting."; exit 1; fi
      
  
    ## iterate DAYs
    for DAY in `seq -w 1 366`; do
      echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      echo "   day ${YEAR}${DAY}"
      
      otFile="EMEP_50km_2_${grid_type}_masked_${YEAR}${DAY}.nc"
      otPath="${dirDatOt}/${grid_type}/${otFile}"
      
      
      ## interpolate on the coarse BSH grid
      echo -e "\n    ~~~ Interpolate and further process the EMEP data ~~~"
      cdo -O seltimestep,${DAY} ${inPath} ${otPath}
      
      ## Test whether output data were written
      if [ ! -r ${otPath} ]; then echo >&2 "The output file ${otPath} was not created (=otPath). Aborting."; exit 1; fi
      
      # add some more descriptive attributes
      ncatted -D 1 -a year_doy,global,c,c,"${YEAR}${DAY}" ${otPath}
      echo ""
    
    done ## iterate DAYs
    
  done ## grids

done ## YEAR

