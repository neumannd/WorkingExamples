## R

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