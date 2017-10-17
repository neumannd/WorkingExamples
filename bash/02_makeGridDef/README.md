## README

### 02_makeGridDef

One script (`makeGridDef.sh`) to create a cdo grid definition file.

A netCDF file containing lon and lat coordinates of a model grid is used to 
create a text grid definition file used by cdo to interpolate data.

**Needed data:** `./COORDS/coords_CD64.x_y_time.nc`

**Location of the output file:** `./GRIDS`