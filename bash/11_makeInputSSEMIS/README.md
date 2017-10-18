## bash

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

      | SST | salinity 
------+-----+----------
German Waters | BSH ku | BSH ku 
non-German North and Baltic Sea | BSH no | BSH no 
other regions | ERA-Interim | constant values* 

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

