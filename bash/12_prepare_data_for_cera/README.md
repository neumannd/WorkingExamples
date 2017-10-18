## bash


### 12_prepare_data_for_cera
The script `combine4CERA_v04_base.sh` was used to process CMAQ output data 
for the publication of the data via CERA. I created the script in a way that 
is *easily* (as easy as possible with limited time for preparation) re-usable 
by colleagues who also want to publish data via CERA. 

The script merges select model output variables (of atmospheric concentrations 
and depositions) as well as meteorological and land-use input data into one 
file per day. Some variables are aggregated during this process and some 
others are newly calculated. The cdos and NCOs are used for this work. 

In future version, I will add example in- and output files. For now, please 
have a look at the data published 
[at CERA](http://cera-www.dkrz.de/WDCC/ui/Compact.jsp?acronym=CCLM_CMAQ_HZG_2008) 
to get an impression of the output.
