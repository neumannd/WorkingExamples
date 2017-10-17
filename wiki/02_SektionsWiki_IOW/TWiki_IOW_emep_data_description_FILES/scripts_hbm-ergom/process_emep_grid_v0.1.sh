#!/bin/bash

# @description We read in EMEP DEP files and interpolate them onto the bsh 
#               grids.
# @author Daniel Neumann, daniel.neumann@io-warnemuende.de
# @date 2017-08-02
# @version 0.1

module load nco cdo netcdf

##############################################################################
#### USER SECTION ############################################################
##############################################################################
## set data directory
dirDatBase="."

dirDatIn="${dirDatBase}/../org"

dirDatOt="${dirDatBase}/../hbm-ergom/files_annual"

dirTools="${dirDatBase}/TOOLS"

# HAVE ALSO A LOOK INTO THE "ADVANCED USER SECTION 1" and "ADVANCED USER SECTION 2" below!!!

##############################################################################
#### END OF USER SECTION #####################################################
##############################################################################

########################################################################
#### ADVANCED USER SECTION 1 ###########################################
########################################################################
ncoScrpt_addAttr="addAttributes.nco"

varCalcAndRename='ddep_nox_all=DDEP_OXN_m2Grid/14;ddep_nred_all=DDEP_RDN_m2Grid/14;wdep_nox_all=WDEP_OXN/14;wdep_nred_all=WDEP_RDN/14;sdep_nox_all=(DDEP_OXN_m2Grid+WDEP_OXN)/14;sdep_nred_all=(DDEP_RDN_m2Grid+WDEP_RDN)/14'
########################################################################
#### END ADVANCED USER SECTION 1 #######################################
########################################################################




### TESTS01
## Test whether needed software is installed:
## (taken from http://stackoverflow.com/a/677212/4612235)
hash cdo 2>/dev/null || { echo >&2 "I require cdo but it is not installed or loaded.  Aborting."; exit 1; }
hash ncap2 2>/dev/null || { echo >&2 "I require ncap2 but it is not installed or loaded.  Aborting."; exit 1; }
hash ncatted 2>/dev/null || { echo >&2 "I require ncatted but it is not installed or loaded.  Aborting."; exit 1; }

## Test whether all directories exist
if [ ! -d ${dirDatIn} ]; then echo >&2 "The input directory ${dirDatIn} does not exist (=dirDatIn). Aborting."; exit 1; fi
if [ ! -d ${dirDatOt} ]; then echo >&2 "The output directory ${dirDatOt} does not exist (=dirDatOt). Aborting."; exit 1; fi
if [ ! -d ${dirTools} ]; then echo >&2 "The tool directory ${dirTools} does not exist (=dirTools). Aborting."; exit 1; fi

## Test whether cdo, nco and R script file exist
if [ ! -e ${ncoScrpt_addAttr} ]; then echo >&2 "The script file ${ncoScrpt_addAttr} does not exist (=ncoScrpt_addAttr). Aborting."; exit 1; fi


## iterate YEARs
for YEAR in `seq 2000 2013`; do
# for YEAR in '2012'; do
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo " year ${YEAR}"
  echo ""
  
  inFile="EMEP50km_rv4.9_3245_day.${YEAR}met_${YEAR}emis_rep2016.nc"
  inPath="${dirDatIn}/${inFile}"
  
  ### TESTS03
  ## Test whether input data exist
  if [ ! -e ${inPath} ]; then echo >&2 "The netCDF input file ${inPath} does not exist (=inPath). Aborting."; exit 1; fi
  
  ## output grid
  for grid_type in 'fine' 'coarse'; do  
  
    otFile="EMEP_50km_2_${grid_type}_masked_${YEAR}.nc"
    otPath="${dirDatOt}/${grid_type}/${otFile}"
    
    cdoGridMASK="${dirTools}/MASKS/LW_MASK_BSH${grid_type}_bool.nc"
    cdoGridDef="${dirTools}/GRIDS/griddef_BSH_MeRamo_${grid_type}"
      
    ### TESTS03
    ## Test whether cdo, nco and R script file exist
    if [ ! -e ${cdoGridDef} ]; then echo >&2 "The cdo grid definition file ${cdoGridDef} does not exist (=cdoGridDef). Aborting."; exit 1; fi
    if [ ! -e ${cdoGridMASK} ]; then echo >&2 "The cdo grid MASK file ${cdoGridMASK} does not exist (=cdoGridMASK). Aborting."; exit 1; fi
    
    
    ## interpolate on the coarse BSH grid
    echo -e "\n~~~ Interpolate and further process the EMEP data ~~~"
    cdo -O ifthen ${cdoGridMASK} -remapbil,${cdoGridDef} -expr,${varCalcAndRename} ${inPath} ${otPath}
    ## Test whether output data were written
    if [ ! -r ${otPath} ]; then echo >&2 "The output file ${otPath} was not created (=otPath). Aborting."; exit 1; fi
    echo ""
    
    # add some description attributes
    ncap2 -D 2 -S ${ncoScrpt_addAttr} ${otPath}
    
    # add some more descriptive attributes
    ncatted -D 2 -a src_file,global,c,c,"${inFile}" \
                 -a this_file,global,c,c,"${otFile}" \
                 ${otPath}
  
  done ## output grid
  
done ## iterate YEARs

