#!/bin/bash

# plot bathymetry of the Baltic Sea
#
# Script downloads and plots Baltic Sea bathymetry.
# NEEDS GMT WITH netCDF-SUPPORT.
#
# @author Daniel Neumann, daniel.neumannATioMINUSwarnemuende.de
# @date 2017-07-07


## set some global plot settings
gmt defaults -Ds > ~/gmt.conf
gmtset COLOR_NAN white
gmtset COLOR_FOREGROUND white
gmtset PS_PAGE_COLOR 255/255/255
gmtset FONT_LABEL 24p,,black
gmtset FONT_ANNOT_PRIMARY 24p,,black

gmtset MAP_TICK_PEN 2p
gmtset MAP_TICK_PEN_PRIMARY 2p
gmtset MAP_TICK_PEN_SECONDARY 1p
gmtset MAP_FRAME_PEN 2p

gmtset MAP_FRAME_WIDTH 10p


## set directories and file names
export datadir='12_data'
export datafile='iowtopo2_rev03.nc'
export datavar='Z_WATER'

export colorfile_neg='bathymetry_neg.cpt'
export colorfile_pos='bathymetry_pos.cpt'
if [ -e ${colorfile_neg} ]; then
  rm ${colorfile_neg}
fi
if [ -e ${colorfile_pos} ]; then
  rm ${colorfile_pos}
fi

export outdir='21_pics'
export outfile='plot_bathymetry.ps'
if [ -e ${outdir}/${outfile} ]; then
  rm ${outdir}/${outfile}
fi


## check directories
if [ -e ${datadir} ]; then
  if [ ! -d ${datadir} ]; then
    echo "Data directory ${datadir} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo "Data directory ${datadir} does not exist. Creating"
  mkdir ${datadir}
fi

if [ -e ${outdir} ]; then
  if [ ! -d ${outdir} ]; then
    echo "Output directory ${outdir} exists but is not a directory. STOP"
    exit 1
  fi
else
  echo "Output directory ${outdir} does not exist. Creating"
  mkdir ${outdir}
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

if [ -e ${datadir}/${datafile} ]; then
  echo "Bathymetry was already extracted. Please remove the bathymetry netCDF to extract"
  echo " it again (${datadir}/${datafile})."
else
  tar -xf iowtopo.nc.tgz -C ${datadir}
fi

if [ ! -e ${datadir}/${datafile} ]; then
  echo "Bathymetry file was not extracted properly. STOP"
  exit 1
fi


## create color map
makecpt -Cbathy -Qi -M -T-500/-0.5 > ${colorfile_neg}
#~ makecpt -Cbathy -Iz -Qi -M -T0.5/500 > ${colorfile_neg}
makecpt -Cbathy -I -Qi -M -T0.5/500 > ${colorfile_pos}


### BASIC PANE (in order to have nicer X/Y positing later on)
echo '.' | gmt pstext -R0/19.5/0/28.2 -JM28 -X+2.0c -Y+2.0c -F+cTL+f,,white -P -K > ${outdir}/${outfile}


## create map
# basemap
psbasemap -R10/30/50/66 -JM17 -B5/4"NSEW" -Xr0.0c -Yr0.0c -K -O >> ${outdir}/${outfile}
# plot bathymetry
grdimage ${datadir}/${datafile}?${datavar} -R -J -C${colorfile_neg} -O -K >> ${outdir}/${outfile}
# re-plot coastline
pscoast -Glightgrey -J -R -Di -K -O >> ${outdir}/${outfile}


## text
# (x, y[, font, angle, justify], text)
echo '13.2 65.0 Baltic Sea' | gmt pstext -R -J -F+jML+f30,,black -O -K >> ${outdir}/${outfile}
echo '12.9 64.3 bathymetry' | gmt pstext -R -J -F+jML+f30,,black -O -K >> ${outdir}/${outfile}


## reference
echo '10.3 51.2 T. Seifert, F. Tauber, B. Kayser: 2001: "A high resolution spherical grid ' | gmt pstext -R -J -F+jML+f14,,black -O -K >> ${outdir}/${outfile}
echo '10.7 50.8 topography of the Baltic Sea - 2nd edition", Baltic Sea Science Congress, ' | gmt pstext -R -J -F+jML+f14,,black -O -K >> ${outdir}/${outfile}
echo '10.7 50.4 Stockholm 25-29. November 2001, www.io-warnemuende.de/iowtopo.' | gmt pstext -R -J -F+jML+f14,,black -O -K >> ${outdir}/${outfile}


## color scale
echo '25.0 53.8 depth [m]' | gmt pstext -R -J -F+jML+f24,,black -O -K >> ${outdir}/${outfile}
psscale -Dg15/52.6+w4.8i+h -Q -Bxf3 -Bxa1 -Bpx -C${colorfile_pos} -J -R -O >> ${outdir}/${outfile}

exit 0