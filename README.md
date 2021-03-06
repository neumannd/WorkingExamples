# Working Examples
This repository contains some examples of my work as an add-on for job applications.

It is divided into four subcategories (sub-directory name in brackets):

   * [bash](#bash) (bash): bash scripts using cdo, NCO, netCDF binaries, GMT, and some default
            command line tools
   * [database](#database) (db): example case for using a database
   * [R](#r) (r_code): R-code for plotting and data processing
   * [wiki](#wiki) (wiki): example wiki articles, which I posted in the past years

**The following examples might be of particular interest:**

   * [bash/04_plot_bathymetry](#04_plot_bathymetry): bash script using GMT to plot bathymetry data
   * [bash/12_prepare_data_for_cera](#12_prepare_data_for_cera): bash script to prepare model output data for the publication at CERA (does not run out-of-the-box but nice to look at)
   * [database/R_TOOLS](#r_tools): two R packages created by me
   * [R/03_explain_ammoniumDryParticles](#03_explain_ammoniumdryparticles): a nice plot script, which creates three schematic figures

**Some Fortran Code is provided in the repository:**

   * [HBM_Tools](https://github.com/neumannd/HBM_tools) (Fortran Code only; using Fortran netCDF-4)


-------

[up](#working-examples)

## Table of Contents

   * [Table of Contents](#table-of-contents)
   * [bash](#bash)
      * [01_makeOCEAN_basic](#01_makeocean_basic)
      * [02_makeGridDef](#02_makegriddef)
      * [03_interpolate2CMAQ](#03_interpolate2cmaq)
      * [04_plot_bathymetry](#04_plot_bathymetry)
      * [11_makeInputSSEMIS](#11_makeInputssemis)
      * [12_prepare_data_for_cera](#12_prepare_data_for_cera)
   * [database](#database)
      * [CREATE_AND_INITIALIZE_DB](#create_and_initialize_db)
      * [DIAGRAMS](#diagrams)
      * [R_TOOLS](#r_tools)
   * [R](#r)
      * [01_basic_plotting](#01_basic_plotting)
      * [02_using_screen](#02_using_screen)
      * [03_explain_ammoniumDryParticles](#03_explain_ammoniumdryparticles)
      * [11_time_series_seasalt](#11_time_series_seasalt)
      * [12_ssemis](#12_ssemis)
      * [13_data_processing_R_NCO](#13_data_processing_r_nco)
      * [14_convertBSH](#14_convertbsh)
      * [21_own_R_packages](#21_own_r_packages)
   * [wiki](#wiki)
      * [01_AbteilungsWiki_HZG](#01_abteilungswiki_hzg)
      * [02_SektionsWiki_IOW](#02_sektionswiki_iow)
      * [03_EigenesWiki](#03_eigeneswiki)

-------

[up](#working-examples)

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

[up](#working-examples)

## database

During my work at the Helmholtz-Zentrum Geesthacht, we validated atmospheric
chemistry transport model simulations with data from the EMEP measurement 
database. EMEP is the *European Measurement and Evaluation Programme*. Within
EMEP, measurement data from European background air quality monitoring 
stations is collected. The data can be freely downloaded from the
[NILU's EBAS database via a web interface](http://ebas.nilu.no).

The EMEP data are provided in one file per year, station, and parameter. Some
parameters can also be summarized in one file. The EMEP files are structured
according to the NASA AMES format. The EMEP format is a bit stricter. To 
simplify the validation process, I
   * wrote R functions to import in the standardized EMEP text files into R
   * created as PostgreSQL database to locally host EMEP data
   * wrote R functions to import EMEP data into the database.

A colleague wrote R functions to export the EMEP data from the database and
visualized them. The three aspects for I was responsible are presented here:

   * `CREATE_AND_INITIALIZE_DB`: set up and initialize database
   * `DIAGRAMS`: Entity Relationship diagram of the database
   * `R_TOOLS`:
      * two R packages, which are for reading EMEP text files 
         (`R_TOOLS/emepTools`) and for importing EMEP data into the database 
         (`R_TOOLS/emepDB`)
      * two R scripts and some dummy data to test the packages

The test script for the `emepDB` packages is also an example for generally 
using the package. Maybe the one or the other reader is interested in it.

In the emepDB package, I use `RODBC` to access the database. ODBC provides 
a universal database access interface. The user needs to have 

   * install the appropriate ODBC package on his/her operating system,
   * installed a PostgreSQL-OBDC driver, and
   * configured the OBDC package to *know* the database
   
This has the advantage that the database does not necessarily need to be a 
PostgreSQL database but any database, for which a ODBC driver is available.
In addition, it is platform independent and the database may either be a 
local one or a remove one. 

In order to fully test/use this example case, one needs to have a PostgreSQL 
server running (for `CREATE_AND_INITIALIZE_DB`) and ODBC configured (`emepDB` 
package). The `emepTools` package runs out of the box.


### CREATE_AND_INITIALIZE_DB

The scripts in the `CREATE_AND_INITIALIZE_DB` folder create the EMEP database,
create necessary tables and fill some tables with predefined data (e.g. station
data). If one has a local PostgreSQL database running and if the current user 
is allowed to create new database, one can just run

    ./create_db_and_do_all.sh

Otherwise, one needs to create the new database manually and call the two SQL 
scripts `create_tables_v02.1.sql` and `fill_tables_v02.1.sql` by hand.


### DIAGRAMS

Just one ER diagram in different formats. I created it with dia, exported it 
to SVG, made some corrections in Inkscape, and exported it to PDF.


### R_TOOLS

The two folders `emepDB` and `emepTools` contain the two R packages. The 
packages are also provided as `*.tar.gz` files in the same folder. The folder
`emepPackagesTesting` contains two R scripts to test the R packages. Some dummy
data is included in `emepPackagesTesting/emep_data`. These are no real data and
they are only provided for testing purposes.

The package `emepTools` has no dependencies. The packages `emepDB` depends on
`emepTools` and on `RODBC`. Each function in `emepDB` exists twice. The 
functions of the format `name.RODBC` expect an open rodbc database connection
as first argument. The functions of the format `name` expect a variable 
`DBaccess` to be set as follows:

    DBaccess <- list(name="ODBC-dsn", uid="USERNAME", pwd="PASSWORD") 

The `ODBC-dsn`, `USERNAME`, and `PASSWORD` need to be replaced. The latter set 
of functions (without `RODBC` in their name) causes some extra opening and 
closing of the database connection. However, they save inexperienced users some
time to deal with the database connection.

For more details on using the packages please consult the test scripts and the
manual pages of the functions.



-------

[up](#working-examples)

## R

Eight examples of my usage of R are provided in the directory `r_code` (`db` 
and `wiki` directories contain some more). Three examples are working out of
the box (`01_*` to `03_*`), whereas four examples contain only code, which
does not run, and corresponding figures (`11_*` to `14_*`). The later code
examples do not work because input data and some script parts are missing
becaues the data are not for public use, the data are too large, or/and 
called code is not my own one. The `21_*` just points to `db/R_TOOLS` where
two R packages are presented.

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


### 21_own_R_packages

Please go to `/db/R_TOOLS` in this repository to see two R packages written 
by me.

-------

[up](#working-examples)

## wiki

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

-------

[up](#working-examples)

