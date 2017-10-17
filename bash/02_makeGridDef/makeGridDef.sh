#!/bin/bash
# Script extracts grid definitions from a netCDF file.
# 
# @author Daniel Neumann, daniel.neumann@hzg.de, ORCID
# @date 30/01/2015
# @version 1.0
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

GRID_NAME='CD24'

inDirr='./COORDS'
inFile="coords_${GRID_NAME}.x_y_time.nc"
# inFile="coords_${GRID_NAME}_ROWCOL.nc"
inPath=${inDirr}/${inFile}

otDirr='./GRIDS'
otFile="griddef_CMAQ_${GRID_NAME}"
otPath=${otDirr}/${otFile}

cdo griddes ${inPath} > ${otPath}
