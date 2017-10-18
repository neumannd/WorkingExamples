## R

### 13_data_processing_R_NCO
The script `relContribPW.R` calculates the relative concentration of tagged 
tracers (model state/prognostic variables) with respect to their un-tagged
counterparts. I wanted to catch some special cases prior to the calculation,
which is why I do it manually. At first a ncap2 (one of the NCOs) calculation
script is created from within R, then ncap2 is called (from within are), and 
then the actual calculations are performed in R.