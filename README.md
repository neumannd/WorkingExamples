# WorkingExamles
This repository contains some examples of my work.

It is divided into four subcategories (sub-directory name in brackets):

   * bash (bash): bash scripts using cdo, NCO, netCDF binaries, GMT, and some default
            command line tools
   * database (db): example case for using a database
   * R (r_code): R-code for plotting and data processing
   * Wikis (wiki): example wiki articles, which I posted in the past years

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

**Reference input data:** T. Seifert, F. Tauber, B. Kayser: 2001: *"A high resolution spherical grid topography of the Baltic Sea - 2nd edition"*, Baltic Sea Science Congress, Stockholm 25-29. November 2001, Poster #147, [www.io-warnemuende.de/iowtopo](https://www.io-warnemuende.de/topography-of-the-baltic-sea.html). 


### 04_plot_bathymetry

This folder contains three scripts (`plot_bathy_main.sh`, `clean_up.sh`, and 
`plot_bathy_convert_ps2png.sh`). The main script `plot_bathy_main.sh` downloads 
Baltic Sea bathymetry data, extracts it and creates a nice plot as PostScript
file. The `plot_bathy_convert_ps2png.sh` script converts the ps file into a 
png image. The `clean_up.sh` script just cleans up the directory in the end.

**Location of the output file (pictures):** `./21_pics`

**Reference input data:** T. Seifert, F. Tauber, B. Kayser: 2001: *"A high resolution spherical grid topography of the Baltic Sea - 2nd edition"*, Baltic Sea Science Congress, Stockholm 25-29. November 2001, Poster #147, [www.io-warnemuende.de/iowtopo](https://www.io-warnemuende.de/topography-of-the-baltic-sea.html). 




### 11_makeInputSSEMIS
The script `make_bsh.sh` combines sea surface temperature (SST) and sea 
surface salinity data of different sources in one file. The output data
served as input data for sea salt emission calculations performed in R 
example `12_ssemis`. Data from operational forcasts of the German Federal
Maritime and Hydrographic Agency (BSH) were used for the North Sea and 
Baltic Sea. They were provided as text files by the BSH and converted 
into netCDF in the first processing step (see the `R` example
`14_convertBSH`).

The table below provides an overview of the data sources used to compile
a Europe-covering SST and salinity field.

| Region | SST | salinity |
| :----- | :-- | :------- |
| German Waters | BSH ku | BSH ku |
| non-German North and Baltic Sea | BSH no | BSH no |
| other regions | ERA-Interim | constant values* |

constant salinity values for other regions (not North Sea, not Baltic Sea):

   * Northeast Atlantic: 35 g/kg
   * Mediterranean Sea: 37 g/kg and higher
   * Black Sea: 15 g/kg   

The input data from different sources are differently split into individual 
files. Some contain one year of data per file and others contain one day of 
data per file. Some daily input and output files are named according to 
YYYYMMDD format and others to YYYYDDD format (day of year). Therefore, we
are handling different date indices, which is not quite nice it a shell 
script.

For each input data source with have a MASK netCDF file. On the base
of these MASK files, the data are merged with cdo (line 164 to 179). 
Afterwards we do some nice-making: remove NaNs, deal with artifacts along
the coastline, renamed dimensions, correct the time variable, and add
global attributes. The output file conforms with the  conventions of the 
CMAS-IOAPI (TFLAG as time variable; dimension names TSTEP, LAY, COL, and 
ROW; global attributes).


### 12_prepare_data_for_cera
The script `combine4CERA_v04_base.sh` was used to process CMAQ output data 
for the publication of the data via CERA. I created the script in a way that 
is *easily* (as easy as possible with limited time for preparation) re-usable 
by colleagues who also want to publish data via CERA. 

The script merges select model output variables (of atmospheric concentrations 
and depositions) as well as meteorological and land-use input data into one 
file per day. Some variables are aggregated during this process and some 
others are newly calculated. The grid (lambert conformal conic projections) is 
not interpolated but properly documented according to CF-conventions. 
Generally, the file conforms with the CF-conventions. There are some standard 
names with ambiguous meaning. Please read the READMe of the CERA data set for 
details. The cdos and NCOs are used for all of this work. 

In future version, I will add example in- and output files. For now, please 
have a look at the data published 
[at CERA](http://cera-www.dkrz.de/WDCC/ui/Compact.jsp?acronym=CCLM_CMAQ_HZG_2008) 
to get an impression of the output.




-------

## DB

TODO


-------

## R

Five examples of my usage of R are provided in the directory `r_code` (`db` 
and `wiki` directories contain some more). Five examples are working out of
the box (`01_*` to `03_*`), whereas four examples contain only code, which
does not run, and corresponding figures (`11_*` to `14_*`). The later code
examples do not work because input data and some script parts are missing
becaues the data are not for public use, the data are too large, or/and 
called code is not my own one.

The example `14_*` is quite a nice one because it contains detailed comments
and shows in a *short* script, how I create a CMAS-IOAPI-conform netCDF file
with R.



### 01_basic_plotting
The script `basic_plotting_png.R` creates three basic plots with some playing
with axes, colors, line types, point types, etc.

### 02_using_screen
The scripts `boxes_demo_1.R`, `boxes_demo_2.R`, and `boxes_demo_3.R` create 
each one png file with differently aligned plots. The `screen` function of
R is used for this purpose. These are mainly basic examples, which I originally
created for our department's wiki.

### 03_explain_ammoniumDryParticles
The script `readme_standardname_problem.R` generates a pdf file containing 
three plots. There plots visualize schematically (a) how atmospheric particles
are in reality, (b) what specific variable names actually mean, and (c) how 
atmospheric particles are represented in many atmospheric chemistry transport
models.

The plot is used in a readme of a data set published
[at CERA](http://cera-www.dkrz.de/WDCC/ui/Compact.jsp?acronym=CCLM_CMAQ_HZG_2008). 
In future the data will be available under the doi 
10.1594/WDCC/CCLM_CMAQ_HZG_2008.


### 11_time_series_seasalt
The script `combine_sim_and_obs_v2.0.0_newPlotOrder.R` was used to create a 
times series plot for a publication. The plot
`fig09_CONC.timeseries.effectSeaSalt.v5.Na.threeStations.newer.pdf` is provided
in this repository and can be also fund in one of my publications
[Neumann et al. (2016)](https://doi.org/10.5194/acp-16-9905-2016).

The script is quite long. The interesting plotting work is done between the 
comments `ACTUAL PLOTTING START` and `ACTUAL PLOTTING END`. I am currently
working on splitting the code into individual functions. The file
`plot_timeseries_obs_mod` is a start doing this. However, it takes some time 
to do it nicely (catch errors of input parameters, ...). 


### 12_ssemis
A set of scripts, which I used to calculated sea salt emissions (=ssemis), for
runs with the CMAQ air quality model. Originally, I indented to create a R
package from these data. But due to missing time and no further use of such a
package, the code was left as it is.

The scripts are also available as supplementary material to a paper availabler
under the doi 
[10.5194/acp-16-9905-2016](https://doi.org/10.5194/acp-16-9905-2016), which is
Neumann et al. (2016).

The script `ssemis_start.R` is the base script, which should be called from the
command line. Specific command line arguments have to be provided as documented
in the start script. It calls of of the `ssemis_main_*.R` scripts, which use 
their corresponding functin in `ssemis_calc_*.R` to calculate sea salt 
emissions. All other functions are not split into individual files but written
in the file `ssemis_funs.R`. Some other external functions are called, for
which I do not have the copyright. These functions are not included. For the
interested reader, a verion log is included in `ssemis_log_version.txt`.

The scripts were originally created in 2014 when I did not have as much 
experiance with and knowledge on R. Therefore, a lot of things could probably
optimized.


### 13_data_processing_R_NCO
The script `relContribPW.R` calculates the relative concentration of tagged 
tracers (model state/prognostic variables) with respect to their un-tagged
counterparts. I wanted to catch some special cases prior to the calculation,
which is why I do it manually. At first a ncap2 (one of the NCOs) calculation
script is created from within R, then ncap2 is called (from within are), and 
then the actual calculations are performed in R.


### 14_convertBSH 
The scripts `read_data_v09.R` and `read_data_BSHcmod3_v09.R` read in text 
output files of the BSHcmod4 and BSHcmod3, respectively, and write the data 
into new netCDF files. Prior to the upload at github, the code was cleaned
up (some out-commented lines were remove) but no comments were added since 
5th Feb. 2015.

These scripts do not run out of the box because some input data is missing.
If you are working with BSH data in the original text format and would like
to use my code you are welcome to contact me.


-------

## Wiki

In diesem Verzeichnis sind einige Beispiele von meinen Beitraegen zu Wikis untergebracht.


### 01_AbteilungsWiki_HZG
Das Institut fuer Kuestenforschung am HZG fuehrt ein eigenes Wiki - ein 
Atlassian Confluence. Die Abteilung, in der ich am HZG gearbeitet habe, hatte
in diesem Wiki ihren eigenen Bereich. Im besagten Unterordner sind PDF-Exporte 
aus dem Atlassian Confluence enthalten. Alle exportieren Artikel stammen
von mir. Bei Zweifeln koennen meine Referenzpersonen am HZG gefragt werden.


### 02_SektionsWiki_IOW
Von den Modellierern der Sektion Physik des IOW wird ein TWiki betrieben. Dort
werden verschiede Dinge dokumentiert (Modelldaten, Aufsetzten von Modellen und
Software, Tipps, Beispiele, Hilfen zur Nutzung von R). PDF Exports and text in
der TWiki Markup Sprache werden hier bereit gestellt. Alle exportieren Artikel 
stammen von mir. Bei Zweifeln koennen meine Referenzpersonen am IOW gefragt 
werden.

Zwei Beispielartikel sind enthalten. Zu jedem Beispiel gibt es den 'Code' 
(TWiki Markup Sprache), den Artikel als PDF und einen Ordner mit 
Zusatzmaterial, das dem Artikel angehaengt war. Dies sind R- und 
Shell-Scripte.


### 03_EigenesWiki
Ein Foswiki (Urspruenlich ein Branch des TWiki) in dem ich verschiedene Dinge
fuer mich dokumentiere:
   * Installation von gelaeufiger Software (netCDF, cdo, ...)
   * Aufrufe bestimmter Kommandozeilenprogramme mit passenden Parametern, die 
      ich immer wieder vergesse: ImageMagick, nco, git, Mencoder, ...
   * Sammlung an einigen laenglichen nco und cdo Aufrufen
   * Dokumentation meiner Arbeit fuer einige Projekte
   * Compilieren einige Modellsysteme
   * Information zu privat genutzter Software und Hardware

