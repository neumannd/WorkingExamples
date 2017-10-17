# WorkingExamles
This repository contains some examples of my work.

It is divided into five subcategories:

   * bash: bash scripts using cdo, NCO, netCDF binaries, GMT, and some default
            command line tools
   * DB: example case for using a database
   * R: TODO
   * Wiki: ...

-------

## bash

These scripts are examples of scripts, which I use as part of my daily 
work. They document the usage of cdo, NCO and netCDF binaries as well as
of bash scripts.

The scripts in the directories `01_*` to `04_*` are running out of the box (for 
`03_*` and `04_*` an active internet connection is needed). Scripts in directories 
`11_*` and `12_*` do not run out of the box because some input file are missing. 
They are not intended to be executable but they should show my programming 
style and the features I use. 

### 01_makeOCEAN_basic

One script (`make_ocean_quick.sh`) to create a input netCDF file for a model run.

This script creates an OCEANfile for CMAQ (Community Multiscale Air Quality 
Model). CMAQ uses CMAS-IOAPI, which is an 'add-on'-library to netCDF. IOAPI 
uses a specific set of global attributes. IOAPI seems to access variables not 
by name but by their index in the netCDF file. Thesefore, variables in netCDF 
input files for CMAQ need to be in a specific order. This script creates a 
netCDF file with the specific variable order and with the needed global 
attributes.

This script cleans up automatically. Please comment out the last line to 
prevent it from doing the cleanup.

**Needed file:** `./GRIDCRO/GRIDCRO2D_cd24_2012001`

**Location of the output file:** `./OCEAN`


### 02_makeGridDef

One script (`makeGridDef.sh`) to create a cdo grid definition file.

A netCDF file containing lon and lat coordinates of a model grid is used to 
create a text grid definition file used by cdo to interpolate data.

**Needed data:** `./COORDS/coords_CD64.x_y_time.nc`

**Location of the output file:** `./GRIDS`


### 03_interpolate2CMAQ

This folder contains two scripts (`interpolate2CMAQ.sh` and `clean_up.sh`). 
The main script `interpolate2CMAQ.sh` downloads Baltic Sea topography data, 
extracts it, and interpolates it from one grid onto another. The second 
script (`clean_up.sh`) is for cleaning up the directory.

**Needed data:** `./GRIDS/griddef_CMAQ_CD24`

**Location of the output file:** `./OUTPUT`

**Reference input data:** T. Seifert, F. Tauber, B. Kayser: 2001: *"A high resolution spherical grid topography of the Baltic Sea - 2nd edition"*, Baltic Sea Science Congress, Stockholm 25-29. November 2001, Poster #147, [www.io-warnemuende.de/iowtopo](http://www.io-warnemuende.de/iowtopo). 


### 04_plot_bathymetry

This folder contains three scripts (`plot_bathy_main.sh`, `clean_up.sh`, and 
`plot_bathy_convert_ps2png.sh`). The main script `plot_bathy_main.sh` downloads 
Baltic Sea bathymetry data, extracts it and creates a nice plot as PostScript
file. The `plot_bathy_convert_ps2png.sh` script converts the ps file into a 
png image. The `clean_up.sh` script just cleans up the directory in the end.

**Location of the output file (pictures):** `./21_pics`

**Reference input data:** T. Seifert, F. Tauber, B. Kayser: 2001: *"A high resolution spherical grid topography of the Baltic Sea - 2nd edition"*, Baltic Sea Science Congress, Stockholm 25-29. November 2001, Poster #147, [www.io-warnemuende.de/iowtopo](http://www.io-warnemuende.de/iowtopo). 


### 11_makeBSH




### 12_prepare_data_for_cera






-------

## DB

TODO


-------

## R

TODO


-------

## Wiki

TODO
