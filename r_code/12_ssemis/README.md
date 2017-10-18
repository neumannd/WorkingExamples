## R

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