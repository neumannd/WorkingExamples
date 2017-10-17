#!/bin/bash

# convert ps to png picture and crop
#
# Script converts a ps file to a png file
# NEEDS IMAGE MAGICK
#
# @author Daniel Neumann, daniel.neumannATioMINUSwarnemuende.de

cd /media/neumannd/work_dell/11_Bewerbung/Arbeitsproben/2017/Bash/04_plot_bathymetry

convert 21_pics/plot_bathymetry.ps -flatten 21_pics/plot_bathymetry.png
