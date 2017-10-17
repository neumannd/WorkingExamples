#!/bin/bash

# Download topography data and interpolate it on a new grid.
#
# Downloads IOW topography data for the Baltic Sea and interpolates it onto 
# the cmaq CD24 grid using cdo. The CMAQ CD24 grid covers the North Sea and
# Baltic Sea. However the data set covers only the Baltic Sea. This is just 
# an example case. Therefore, we ignore this issue. A grid definition has 
# to exist in the folder 'GRIDS'.
#
# @author Daniel Neumann, daniel.neumannATioMINUSwarnemuende.de

## CMAQ grid
GRID_NAME='CD24'


## directory and file names
inDirr='./INPUT'
inFile='iowtopo2_rev03.nc'
inPath=${inDirr}/${inFile}

grdDirr='./GRIDS'
grdFile="griddef_CMAQ_${GRID_NAME}"
grdPath=${grdDirr}/${grdFile}

otDirr='OUTPUT'
otFile="iowtopo2_rev03_CMAQ_${GRID_NAME}.nc"
otPath=${otDirr}/${otFile}


## check directories and files
if [ -e ${inDirr} ]; then
  if [ ! -d ${inDirr} ]; then
    echo "Data directory ${inDirr} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo "Data directory ${inDirr} does not exist. Creating"
  mkdir ${inDirr}
fi

if [ -e ${otDirr} ]; then
  if [ ! -d ${otDirr} ]; then
    echo "Output directory ${otDirr} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo "Output directory ${otDirr} does not exist. Creating"
  mkdir ${otDirr}
fi

if [ ! -e ${grdDirr} ]; then
  echo -e "\n  Grid definition directory ${grdDirr} missing. STOP"
  exit 1
fi
if [ ! -f ${grdPath} ]; then
  echo -e "\n  Grid definition data ${grdPath} missing. STOP"
  exit 1
fi


## obtain and extract bathymetry
if [ -e iowtopo.nc.tgz ]; then
  echo "Bathymetry was already downloaded. Please remove iowtopo.nc.tgz if you want to "
  echo " download it again."
else
  echo "Download bathymetry data of the IOW."
  wget -nv https://www.io-warnemuende.de/tl_files/forschung/mediathek/iowtopo/iowtopo.nc.tgz
fi

if [ ! -e iowtopo.nc.tgz ]; then
  echo "Bathymetry file iowtopo.nc.tgz could not be downloaded. STOP"
  exit 1
fi

if [ -e ${inPath} ]; then
  echo "Bathymetry was already extracted. Please remove the bathymetry netCDF to extract"
  echo " it again (${inPath})."
else
  tar -xf iowtopo.nc.tgz -C ${inDirr}
fi

if [ ! -e ${inPath} ]; then
  echo "Bathymetry file was not extracted properly. STOP"
  exit 1
fi


## interpolate input data to CMAQ CD24 grid
cdo -s remapbil,${grdPath} ${inPath} ${otPath} 