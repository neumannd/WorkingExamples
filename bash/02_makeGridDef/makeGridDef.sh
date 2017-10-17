#!/bin/bash
# Script extracts grid definitions from a netCDF file.
# 
# @author Daniel Neumann, daniel.neumannATioMINUSwarnemuende.de
# @date 17/10/2015
# @version 1.1
#
# original location: /storage/neumannd/data/tools/makeGRID

# precondtions: Our infile has LON and LAT coordinates as
#  variables. Those spatial resolved variables to which
#  the LON and LAT coordinates belong have set an attribute
#  'coordinates = "LON LAT"'.
#
# To get a file defined in the preconditions, one can call
# makeCoords.sh first for getting coordinates from the MET
# and then addCoords.sh to add the coordinates to a chosen
# file. On the resulting file, this script can be applied.
# 
# make record dimensions:
#  ncks -a --mk_rec_dmn TSTEP ${IN} ${OUT}
#

# cd /media/neumannd/work_dell/11_Bewerbung/Arbeitsproben/2017/Bash/02_makeGridDef

GRID_NAME='CD64'

## set file and directory names
inDirr='./COORDS'
inFile="coords_${GRID_NAME}.x_y_time.nc"
# inFile="coords_${GRID_NAME}_ROWCOL.nc"
inPath=${inDirr}/${inFile}

otDirr='./GRIDS'
otFile="griddef_CMAQ_${GRID_NAME}"
otPath=${otDirr}/${otFile}


## create directories if necessary
if [ ! -e ${inDirr} ]; then
  echo -e "\n  Data directory ${inDirr} missing. STOP"
  exit 1
fi
if [ ! -f ${inPath} ]; then
  echo -e "\n  Input data ${inPath} missing. STOP"
  exit 1
fi

if [ -e ${otDirr} ]; then
  if [ ! -d ${otDirr} ]; then
    echo -e "\n  Output directory ${otDirr} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo -e "\n  Output directory ${otDirr} does not exist. Creating"
  mkdir ${otDirr}
fi


## extract grid definition
cdo griddes ${inPath} > ${otPath}
