#!/bin/bash

# This script combines BSHcmod SST data and ERA-Interim SST data into one
# netCDF file per day and grid type.
#
# @author Daniel Neumann
# @version 1.2
# @date 2015-03-12 (code-cleanup in Oct. 2017)
#
# original location: /storage/neumannd/data/tools/combineDATA

dateYYYY='2008'

GRID_NAME='CD06'
grid_name='cd06'

case "${GRID_NAME}" in
  "CD72" )
    nCols=57
    nRows=66
    XORIG="-1926000.0"
    YORIG="-2655000.0"
    XCELL="72000.0"
    YCELL="72000.0" ;;
  "CD24" )
    nCols=112
    nRows=106
    XORIG="-1398000.0"
    YORIG="-1191000.0"
    XCELL="24000.0"
    YCELL="24000.0" ;;
  "CD06" )
    nCols=160
    nRows=157
    XORIG="-672000.0"
    YORIG="-537000.0"
    XCELL="6000.0"
    YCELL="6000.0" ;;
  "AQ24" )
    nCols=171
    nRows=198
    XORIG="-1926000.0"
    YORIG="-2655000.0"
    XCELL="24000.0"
    YCELL="24000.0" ;;
  * )
    nCols=-1
    nRows=-1
    XORIG="0.0"
    YORIG="0.0"
    XCELL="0.0"
    YCELL="0.0" ;;
esac


# Choose whether the coastline should be interpolated in more detail or not.
# Setting HI_RES_COAST to FALSE will make the script run faster.
# If HI_RES_COAST is TRUE then the 'cdo' call below which interpolates onto
# the chosen CMAQ grid will us 'remapdis' instead of 'remapbil'. 'remapbil' does
# bilinear interpolation with all neighbouring grid points. If at least one 
# grid point is 'NA' then the result will also be 'NA'. 'remapdis' seems to 
# use the same formular as 'remapbil' but neighbour points which are 'NA's are
# ignored. 
HI_RES_COAST=true
# HI_RES_COAST=false


## Option for 'cdo remapdis': If set to OFF then not interpolation outside the
## region takes place.
# export REMAP_EXTRAPOLATE=ON
export REMAP_EXTRAPOLATE=OFF


# baseDir='/media/tmp_mn'
# baseDir='/media/neumannd/tmp_mn'
baseDir='/home/neumannd/storage/neumannd'

# directories
inDirrMsk="${baseDir}/data/tools/MASKS"
inDirrGrd="${baseDir}/data/tools/GRIDS"
inDirrSstERA="${baseDir}/data/sst/infiles/era_interim"
inDirrSalERA="${baseDir}/data/salt/infiles/era_interim"
inDirrWaveERA="${baseDir}/data/waves/infiles/era_interim"
inDirrBSH="${baseDir}/data/bsh/infiles/BSHcmod4"
otDirr="${baseDir}/data/bsh/outfiles/${GRID_NAME}"
tpDirr="${baseDir}/data/bsh/outfiles/${GRID_NAME}"

inDirrCalender="${baseDir}/data/tools/CALENDERS"
inFileCalenderYYYYDDD="calender_${dateYYYY}DDD.csv"
inFileCalenderYYYYMMDD="calender_${dateYYYY}MMDD.csv"


# read files, idea comes from
# http://stackoverflow.com/questions/11393817/bash-read-lines-in-file-into-an-array
IFS=$'\n' read -d '' -r -a datesYYYYDDD < ${inDirrCalender}/${inFileCalenderYYYYDDD}
IFS=$'\n' read -d '' -r -a datesYYYYMMDD < ${inDirrCalender}/${inFileCalenderYYYYMMDD}

fLenA=${#datesYYYYDDD[@]}
fLenB=${#datesYYYYMMDD[@]}

if [[ "${fLenA}" -ne "${fLenB}" ]];
then
  echo "Calender files have different number of lines: ${fLenA} vs. ${fLenB}."
  echo ${inDirrCalender}/${inFileCalenderYYYYDDD}
  echo ${inDirrCalender}/${inFileCalenderYYYYMMDD}
else

  ## FOR
  for (( i1=51; i1<102; i1++ )); do
    
    ## set date variables needed below
    # julian date  as 'YYYYDDD'
    dateYYYYDDD=${datesYYYYDDD[${i1}]}
    # common date as 'YYYYMMDD'
    dateYYYYMMDD=${datesYYYYMMDD[${i1}]}
    # common date as 'YYYY-MM-DD'
    dateYYYY_MM_DD="${dateYYYYMMDD:0:4}-${dateYYYYMMDD:4:2}-${dateYYYYMMDD:6:2}"
    # common date as 'YYYY-MM-DD,00:00:00,1hour'
    dateTimeInt="${dateYYYY_MM_DD},00:00:00,1hour"
    
    ## DEBUGGING
    # echo ${dateYYYYDDD} ${dateYYYYMMDD}
    # echo ${dateTimeInt}
    # echo ${dateYYYY_MM_DD}
    
    # Take time steps at 0, 6, 12, 18 and 24 o'clock. 24 is dropped later
    timeSteps="$(($i1*4+1)),$(($i1*4+2)),$(($i1*4+3)),$(($i1*4+4)),$(($i1*4+5))"
    
    ## DEBUGGING
    # echo ${timeSteps}

    # file names
    inFileWaveERA="interim_swh_${dateYYYY}_lonlat_one.nc"

    # combine path
    inPathGrd=${inDirrGrd}/"griddef_CMAQ_${GRID_NAME}"

    inPathSstKU=${inDirrBSH}/"bsh_t_latlon_${dateYYYYDDD}_ku.nc"
    inPathSstNO=${inDirrBSH}/"bsh_t_latlon_${dateYYYYDDD}_no.nc"
    inPathSstERA=${inDirrSstERA}/"interim_sst_${dateYYYY}_lonlat_half_p1.nc"
    # The file below is a fake-file. It just contains constant salinities.
    inPathSalERA=${inDirrSalERA}/"interim_SAL_${GRID_NAME}.nc"
    inPathMskKU=${inDirrMsk}/"MASK_ku2${GRID_NAME}_SST.nc"
    inPathMskNO=${inDirrMsk}/"MASK_no2${GRID_NAME}_SST.nc"
    inPathMskERA=${inDirrMsk}/"MASK_era2${GRID_NAME}_SST.nc"
    inPathMskLW=${inDirrMsk}/"LW_MASK_${GRID_NAME}.nc"
    inPathWeightsKU=${inDirrWeights}/"intWeight_remapdis_${GRID_NAME}_SST_KU.nc"
    inPathWeightsNO=${inDirrWeights}/"intWeight_remapdis_${GRID_NAME}_SST_NO.nc"
    inPathWeightsERA=${inDirrWeights}/"intWeight_remapdis_${GRID_NAME}_SST_ERA.nc"
    inPathWeightsKU=${inDirrWeights}/"intWeight_remapdis_${GRID_NAME}_Sal_KU.nc"
    inPathWeightsNO=${inDirrWeights}/"intWeight_remapdis_${GRID_NAME}_Sal_NO.nc"

    ouPath=${otDirr}/"bsh_combined_${GRID_NAME}_${dateYYYYDDD}.nc"
    tpPath=${tpDirr}/"tmp_${GRID_NAME}_${dateYYYYDDD}.nc"
    
    # combine data from different grids:
    #  - salinity: BSH ku for German waters
    #              BSH no for non-German North and Baltic Sea Waters
    #              constant salinity for other regions
    #  - SST: BSH ku for German waters
    #         BSH no for non-German North and Baltic Sea Waters
    #         ERA-Interim SST for other regions
    #          (not sure were they get it from ...)
    if [[ "${HI_RES_COAST}" = true ]];
    then
      cdo -O ifthenelse ${inPathMskKU} -remap,${inPathGrd},${inPathWeightsKU} -selname,SALINITY ${inPathSstKU} -ifthenelse ${inPathMskNO} -remap,${inPathGrd},${inPathWeightsNO} -selname,SALINITY ${inPathSstNO} -settaxis,${dateTimeInt} -ifthen ${inPathMskERA} ${inPathSalERA} ${tpPath}
      cdo -O ifthenelse ${inPathMskKU} -addc,273.3 -remap,${inPathGrd},${inPathWeightsKU} -selname,SST ${inPathSstKU} -ifthenelse ${inPathMskNO} -addc,273.3 -remap,${inPathGrd},${inPathWeightsNO} -selname,SST ${inPathSstNO} -ifthen ${inPathMskERA} -remap,${inPathGrd},${inPathWeightsERA} -seldate,${dateYYYY_MM_DD} -inttime,${dateTimeInt} -seltimestep,${timeSteps} ${inPathSstERA} ${ouPath}
    else
      cdo ifthenelse ${inPathMskKU} -remapbil,${inPathGrd} -selname,SALINITY ${inPathSstKU} -ifthenelse ${inPathMskNO} -remapbil,${inPathGrd} -selname,SALINITY ${inPathSstNO} -settaxis,${dateTimeInt} -ifthen ${inPathMskERA} ${inPathSalERA} ${tpPath}
      
      ## NOTE: Use renapdis when you want to have more data along the coast. It takes
      ##   considerably longer!!!
      if [[ "${GRID_NAME}" = "CD24" ]];
      then
        cdo ifthenelse ${inPathMskKU} -addc,273.3 -remapbil,${inPathGrd} -selname,SST ${inPathSstKU} -ifthenelse ${inPathMskNO} -addc,273.3 -remapbil,${inPathGrd} -selname,SST ${inPathSstNO} -ifthen ${inPathMskERA} -remapdis,${inPathGrd} -seldate,${dateYYYY_MM_DD} -inttime,${dateTimeInt} -seltimestep,${timeSteps} ${inPathSstERA} ${ouPath}
      else
        cdo ifthenelse ${inPathMskKU} -addc,273.3 -remapbil,${inPathGrd} -selname,SST ${inPathSstKU} -ifthenelse ${inPathMskNO} -addc,273.3 -remapbil,${inPathGrd} -selname,SST ${inPathSstNO} -ifthen ${inPathMskERA} -remapbil,${inPathGrd} -seldate,${dateYYYY_MM_DD} -inttime,${dateTimeInt} -seltimestep,${timeSteps} ${inPathSstERA} ${ouPath}
      fi
    fi
    
    # put sst and salinity together into one file
    ncks -A -v SALINITY ${tpPath} ${ouPath}
    
    # get appropriate NaN values
    cdo -O ifthen -gtc,0.0 ${ouPath} ${ouPath} ${tpPath}
    
    # interpolate to coast
    Rscript interpolate2coast_args.R ${tpPath} 'SST' -i 3
    Rscript interpolate2coast_args.R ${tpPath} 'SALINITY' -i 3
    
    # cut coast
    cdo ifthen ${inPathMskLW} ${tpPath} ${ouPath}
    
    # rename dimensions and variables
    ncrename -O -d x,COL -d y,ROW -d time,TSTEP ${ouPath} ${tpPath}
    
    # add TSTEP variable
    ncap2 -O -S createTFLAG_VAR2.nco ${tpPath} ${ouPath}
    Rscript createTFLAG.R ${ouPath} ${dateYYYYDDD}
    
    # modify global variables
    ncatted -a SDATE,global,d,, -a SDATE,global,c,i,${dateYYYYDDD} -a 'TSTEP',global,m,i,'10000' -a 'NCOLS',global,m,i,${nCols} -a 'NROWS',global,m,i,${nRows} -a "NVARS",global,m,i,2 -a 'VGLVLS',global,c,f,"1.0, 0.994898" -a 'GDTYP',global,m,i,2 -a 'GDNAM',global,m,c,"${GRID_NAME}" -a 'XORIG',global,c,f,${XORIG} -a 'YORIG',global,c,f,${YORIG} -a 'XCELL',global,c,f,${XCELL} -a 'YCELL',global,c,f,${YCELL} -a 'P_ALP',global,c,f,"30.0" -a 'P_BET',global,c,f,"60.0" -a 'P_GAM',global,c,f,"10.0" -a 'XCENT',global,c,f,"10.0" -a 'YCENT',global,c,f,"55.0" -a 'VGTOP',global,c,f,"2000.0" -a 'VGTYP',global,c,i,2  ${ouPath}
		
    rm ${tpPath}
  done
  
fi
