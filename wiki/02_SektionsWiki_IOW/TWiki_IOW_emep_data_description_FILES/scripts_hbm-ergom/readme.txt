
Interpolate EMEP grid to BSH fine and coarse grids (one file per model year):
  process_emep_grid_v0.1.sh

The EMEP data are daily mean values. All 365 (or 366) mean values per year are
saved in one files for that year. To get daily files one needs to split the
annual files up.

Split annual files into daily files:
  extract_emep_daily_dep_v0.1.sh

The new files do not have a date as 'yyyymmdd' but 'yyyyddd'. 'ddd' is the 
'day of year' ('doy'), which goes from 1 to 365 (or 366).

This scripts 
