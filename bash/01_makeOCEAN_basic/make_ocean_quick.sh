#!/bin/bash

# The script creates an ocean file based on a GRIDCRO2D file. The surf zone 
# is set to 0 everywhere (=> no surf zone emis).
#
# @author: Daniel Neumann, daniel.neumann@hzg.de
# @date: 2017-10-17
# @version: 1.3
#
# Preconditions / Needed Data
#  GRIDCRO2D file $METEO_IN_NAME in $METEO_DIR
#
# Note 1: Inland water bodies are masked out for the CN06 grid.
#
# Handling:
#  - change 'cd ...' in the beginning
#  - adapt GRID_NAME and grid_name
#  - adapt METEO_IN_NAME (particularly the date!!!) and OCEAN_OUT_NAME
#  - adapt TMP_DIR, METEO_DIR and OUT_DIR


## change into the appropriate directory
# cd .
# cd /media/neumannd/work_dell/11_Bewerbung/Arbeitsproben/2017/Bash/01_makeOCEAN_basic
echo 'Current dir:'
echo `pwd`

## create calculated script file for a call of 'ncap2':
echo 'defdim("LAY",1);' > addLAY_dim.nco
echo '' >> addLAY_dim.nco
echo 'XMASK[$time,$LAY,$y,$x]=MASK;' >> addLAY_dim.nco
echo 'YSURF[$time,$LAY,$y,$x]=SURF;' >> addLAY_dim.nco
echo 'ZOPEN[$time,$LAY,$y,$x]=OPEN;' >> addLAY_dim.nco


## grid name
GRID_NAME='CD24'
grid_name=${GRID_NAME,,}  # lower case version!


## File Names
METEO_IN_NAME=GRIDCRO2D_${grid_name}_2012001
OCEAN_OUT_NAME=OCEAN_${GRID_NAME}_sf000m_basic.nc


## Directories
TMP_DIR='./tmp'
METEO_DIR="./GRIDCRO"
OUT_DIR="./OCEAN"


## check directories
if [ -e ${TMP_DIR} ]; then
  if [ ! -d ${TMP_DIR} ]; then
    echo "Temp directory ${TMP_DIR} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo "Temp directory ${TMP_DIR} does not exist. Creating"
  mkdir ${TMP_DIR}
fi

if [ -e ${OUT_DIR} ]; then
  if [ ! -d ${OUT_DIR} ]; then
    echo "Output directory ${OUT_DIR} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo "Output directory ${OUT_DIR} does not exist. Creating"
  mkdir ${OUT_DIR}
fi

if [ ! -e ${METEO_DIR} ]; then
  echo "Data directory ${METEO_DIR} missing. STOP"
  exit 1
  if [ ! -f ${METEO_IN_NAME} ]; then
    echo "Input data ${METEO_IN_NAME} missing. STOP"
    exit 1
  fi
fi


## Copy the GRIDCRO2D file and make TSTEP to the record dimension
ncks -O --mk_rec_dmn TSTEP ${METEO_DIR}/${METEO_IN_NAME} ${TMP_DIR}/cn06.nc

## Calculate the OPEN varianle from the LUFRAC_16 and LWMASK variables and
## write everything into a tmp file.
# OPEN = LUFRAC_16 * ((-1) * (LWMASK - 1))
cdo chname,LUFRAC_16,OPEN -mul -selname,LUFRAC_16 ${TMP_DIR}/cn06.nc -mulc,-1 -subc,1 -selname,LWMASK ${TMP_DIR}/cn06.nc ${TMP_DIR}/tmp01.nc

## Remove some water grind cells from the new OPEN variable
# Otherwise, large lakes and river deltas who we open ocean regions.
case ${GRID_NAME} in
    "CN06")
       cdo setcindexbox,0,1,90,55,100 -setcindexbox,0,1,68,0,100 -setcindexbox,0,90,100,1,10 -setcindexbox,0,110,115,10,24 -setcindexbox,0,125,140,84,100 ${TMP_DIR}/tmp01.nc ${TMP_DIR}/tmp02.nc
       ;;
    *)
       cdo -O -s copy ${TMP_DIR}/tmp01.nc ${TMP_DIR}/tmp02.nc
       ;;
esac


## Create SURF and MASK variables from the OPEN variables and write them into
## another tmp file.
# SURF = 0.0 * OPEN
# MASK(i,j) = IF( OPEN(i,j) == 0 )      0.0 * OPEN(i,j)
#             ELSE IF( OPEN(i,j) == 1 ) 2.0 + 0.0 * OPEN(i,j)
#             ELSE                      1.0 + 0.0 * OPEN(i,j)
cdo -O merge -chname,OPEN,SURF -mulc,0 -selname,OPEN ${TMP_DIR}/tmp02.nc -selname,OPEN ${TMP_DIR}/tmp02.nc -chname,OPEN,MASK -ifthenelse -eqc,0 -selname,OPEN ${TMP_DIR}/tmp02.nc -mulc,0 -selname,OPEN ${TMP_DIR}/tmp02.nc -ifthenelse -eqc,1 -selname,OPEN ${TMP_DIR}/tmp02.nc -addc,2 -mulc,0 -selname,OPEN ${TMP_DIR}/tmp02.nc -addc,1 -mulc,0 -selname,OPEN ${TMP_DIR}/tmp02.nc ${TMP_DIR}/tmp03.nc

## Copy the TFLAG variable from the modified GRIDCRO2D file into an extra
## tmp files and duplicate that file.
ncks -O -v TFLAG -d VAR,0,2 ${TMP_DIR}/cn06.nc ${TMP_DIR}/tmp04.nc
cp ${TMP_DIR}/tmp04.nc ${TMP_DIR}/tmp08.nc

## Copy MASK, OPEN, and SURF into new variables which have the additional 
## dimension LAY (=1). Then remove the old variables and rename some dimensions.
#### JUST FOR SPECIFIC cdo INSTALLATIONS
#### IF WE DO NOT HAVE SUCH A SPECIFIC VERSION, WE JUST RENAME VARIABLES IN ORDER
#### TO REORDER THEM BY THE NEXT ncks CALL. THE ORDER OF THE VARIABLES IS IMPORTANT
#### FOR THE CMAS IOAPI!!!!
ncrename -O -v MASK,XMASK -v SURF,YSURF -v OPEN,ZOPEN ${TMP_DIR}/tmp03.nc ${TMP_DIR}/tmp06.nc
ncrename -O -d time,TSTEP ${TMP_DIR}/tmp06.nc ${TMP_DIR}/tmp07.nc
# ncap2 -O -S addLAY_dim.nco ${TMP_DIR}/tmp03.nc ${TMP_DIR}/tmp05.nc
# ncks -O -x -v MASK,OPEN,SURF ${TMP_DIR}/tmp05.nc ${TMP_DIR}/tmp06.nc
# ncrename -O -d x,COL -d y,ROW -d time,TSTEP ${TMP_DIR}/tmp06.nc ${TMP_DIR}/tmp07.nc

## Copy the copied variables with the extra dimension into the file with the
## TFLAG variable and rename the MASK, SURF, and OPEN variables to their old
## names.
ncks -A -v XMASK,YSURF,ZOPEN ${TMP_DIR}/tmp07.nc ${TMP_DIR}/tmp08.nc
ncrename -O -v XMASK,MASK -v YSURF,SURF -v ZOPEN,OPEN ${TMP_DIR}/tmp08.nc ${TMP_DIR}/tmp09.nc

## Finally, add some global attributes.
ncatted -O -a 'VAR-LIST',global,m,c,'MASK            SURF            OPEN            ' -a FILEDESC,global,m,c,'OCEAN file' -a units,MASK,o,c,'none            ' -a long_name,MASK,o,c,"MASK            " -a var_desc,MASK,o,c,"2=open ocean, 1=coastline, 0=other" -a units,OPEN,o,c,'none            ' -a long_name,OPEN,o,c,"OPEN            " -a var_desc,OPEN,o,c,"open ocean area / total area" -a units,SURF,o,c,'none            ' -a long_name,SURF,o,c,"SURF            " -a var_desc,SURF,o,c,"surf zone area / total area" -a GDNAM,global,m,c,"CN06" -a UPNAM,global,o,c,"OCEAN" -a NVARS,global,o,i,3 ${TMP_DIR}/tmp09.nc ${TMP_DIR}/${OCEAN_OUT_NAME}


echo -e "\n  Move Ocean file to output directory."
mv ${TMP_DIR}/${OCEAN_OUT_NAME} ${OUT_DIR}/${OCEAN_OUT_NAME}

echo -e "\n  Remove temporary files."
rm ${TMP_DIR}/tmp*.nc ${TMP_DIR}/cn06.nc *.nco
