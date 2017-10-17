#' ssemis_params
#' 
#' This script is part of a sea salt emissions calculation programme. The programme
#' calculates sea salt emissions according to the sea salt emission function by 
#' Ovadnevaite et al. (2014) and Spada et al. (2013). This script provides 
#' functions for checking whether the correct versions of each script are called.
#' 
#' @author Daniel Neumann
#' @date 2015-Nov-06
#' @version 4.0.1
#' 

source('ssemis_versioning.R')

# User Section: Path and file names ----
# dBASE = '/storage'
dBASE = '/ocean-storage'
dBASEIN1 = paste(dBASE, 'neumannd/data', sep = '/')
dBASEIN2 = paste(dBASE, 'M3HOME/data', sep = '/')
dBASEOUT = paste(dBASE, 'neumannd/data', sep = '/')

strDummyDate = '2008370'


# Where are we? ----
#' Maybe directories should be set on the base of the computer/machine?
#' This might be sensible when we have mounted input and output file system
#' in different folders on different machines
myComputer = Sys.info()[["nodename"]] 

# if (myComputer == "RZNP0466L") { wd_base = '/media/work_mn/65_R/sea_salt_emissions_NEW/src'
# # if (myComputer == "RZNP0466L") { wd_base = '/home/neumannd/TMP/ssemis'
# } else if (myComputer == "grpsrv09") { wd_base = '/home/neumannd/home/neumannd/work/65_R/sea_salt_emissions_NEW/src'
# } else if (myComputer == "ifksrv01") { wd_base = '/home/neumannd/work/65_R/sea_salt_emissions_NEW/src'
# } else { wd_base = '.' }
# 
# setwd(paste(wd_base, 'ssemis_v4.0.1', ssemis_version$main, sep = '/'))



# functions to set parameters ----
#' TODO: Documentation
set_base_directories <- function(namespace, GRID_NAME, strYear, myBASEIN1=dBASEIN1, myBASEIN2=dBASEIN2, myBASEOUT=dBASEOUT) {
  # general
  dBASEIN1 <<- myBASEIN1
  dBASEIN2 <<- myBASEIN2
  dBASEOUT <<- myBASEOUT
  
  # input
  namespace$BSH$dir = paste(myBASEIN1, 'bsh/outfiles', GRID_NAME, sep = '/')
  namespace$WAVE$dir = paste(myBASEIN1, 'waves/outfiles', GRID_NAME, sep = '/')
  namespace$MC2D$dir = paste(myBASEIN2, 'lmmcip', GRID_NAME, strYear, sep = '/')
  namespace$MC3D$dir = paste(myBASEIN2, 'lmmcip', GRID_NAME, strYear, sep = '/')
  namespace$COORD$dir = paste(myBASEIN1, 'tools/COORDS', sep = '/')
  
  namespace$OCEAN$wSZ$dir = paste(myBASEIN2, 'ocean/sf050m_GIS', sep = '/')
  namespace$OCEAN$nSZ$dir = paste(myBASEIN2, 'ocean/sf000m_GIS', sep = '/')
  
  # output
  # namespace$OUT$dir = paste(myBASEOUT, 'ssemis', GRID_NAME, strYear, sep = '/')
  namespace$OUT$dir = paste(myBASEOUT, GRID_NAME, strYear, sep = '/')
  
  # namespace
  namespace$BASE$IN1 = myBASEIN1
  namespace$BASE$IN2 = myBASEIN2
  namespace$BASE$OUT = myBASEOUT
  
  return(namespace)
}

#' TODO: Documentation
set_namesspace <- function(namespace, GRID_NAME, strDate, FUN = 'XX99', MODE = 0, SURF = 'wSZ', SAL = 'wSL', AERO = 'ae5') {
  strYear = substr(strDate, 1, 4)
  grid_name = tolower(GRID_NAME)
  namespace = set_base_directories(namespace, GRID_NAME, strYear)
  
  #' output file names
  namespace$OUT$file = paste('ssemis', GRID_NAME, AERO, 
                             paste('OC', SURF, SAL, sep = ''), 
                             FUN, 
                             paste('mode', formatC(MODE, format='d'), sep = ''),
                             strDate, sep = '_')
  
  #' input file names
  namespace$MC2D$file = paste('METCRO2D_', grid_name,'_', strDate, sep = '')
  namespace$MC3D$file = paste('METCRO3D_', grid_name,'_', strDate, sep = '')
  namespace$BSH$file = paste('bsh_combined_', GRID_NAME,'_', strDate, '.nc', sep = '')
  namespace$WAVE$file = paste('era_combined_', GRID_NAME,'_', strDate, '.nc', sep = '')
  namespace$COORD$file = paste('coords_', GRID_NAME,'_ROWCOL.nc', sep = '')
  
  namespace$OCEAN$wSZwSL$file = paste('OCEAN', GRID_NAME, 'sf050m_GIS_ubound_sal.nc', sep = '_')
  namespace$OCEAN$wSZnSL$file = paste('OCEAN', GRID_NAME, 'sf050m_GIS_ubound.nc', sep = '_')
  namespace$OCEAN$nSZwSL$file = paste('OCEAN', GRID_NAME, 'sf000m_GIS_ubound_sal.nc', sep = '_')
  namespace$OCEAN$nSZnSL$file = paste('OCEAN', GRID_NAME, 'sf000m_GIS_ubound.nc', sep = '_')
  
  
  #' pit directories aM83M03(rs, 9, 283)nd file names together
  for(iType in c('BSH', 'WAVE', 'MC2D', 'MC3D', 'OUT', 'COORD')) {
    namespace[[iType]]$path = paste(namespace[[iType]]$dir, namespace[[iType]]$file, sep = '/')
  }
  
  for (iType in c('wSZwSL', 'wSZnSL', 'nSZwSL', 'nSZnSL')) {
    namespace$OCEAN[[iType]]$path = paste(namespace$OCEAN[[substr(iType, 1, 3)]]$dir, namespace$OCEAN[[iType]]$file, sep = '/')
  }
  
  return(namespace)
}



# physical parameters ----
  # density of sea salt
# rhoSS = 2         # g/cm^3
rhoSS = 2.2         # g/cm^3
  # gas constant
R = 8.3144621     # J / (mol * K)
  # molar mass of water
M_H2O = 18        # g / mol



# dummy values for some initialisations ---- 
gridNames = c('CD72', 'CD24', 'CD06')
# GRID_NAME = 'CD06'
# GRID_NAME = 'CD24'
GRID_NAME = 'CD72'
grid_name = tolower(GRID_NAME)



# defined modes and mode names ----
modeNumb = c('I', 'J', 'K')
modeNameShort = c('ATKN', 'ACC', 'COR') 
modeNameLong = c('Aitken', 'Accumulation', 'Coarse')
# modeName = array(c('ATKN', 'Aitken', 'ACC', 'Accumulation', 'COR', 'Coarse'), dim = c(2,3))



# sea salt splits ----
#' Note: How to distinguish between 'with I mode' and 'without I mode'?
#'        Each split exists twice: once with a 'b' before the '_' and 
#'        once without 'b'. The variable with 'b' contains I mode and
#'        without 'b' does not.

#' CMAQ v4.6 with aero4 and cb05
#' place: CCTM/src/vdiff/acm2/ssemis.F,v
CMAQ46aero4_split = array(c(-1,-1,-1,0.3856,0.5389,0.0755,0.3856,0.5389,0.0755), dim = c(3,3))
CMAQ46aero4_specs = c('NA', 'CL', 'SO4')
CMAQ46aero4_modes = c('I', 'J', 'K')

#' CMAQ v4.7.1 with aero5 and cb05
#' place: CCTM/src/vdiff/acm2/ssemis.F,v
CMAQ47aero5_split = array(c(-1,-1,-1,0.3856,0.5389,0.0755,0.3856,0.5389,0.0755), dim = c(3,3))
CMAQ47aero5_specs = c('NA', 'CL', 'SO4')
CMAQ47aero5_modes = c('I', 'J', 'K')

#' CMAQ v5.0.1 with aero5 and cb05
#' place: CCTM/src/aero/aero5/AERO_DATA.F,v
CMAQ50aero5_split = array(c(-1,-1,-1,0.0755,0.5389,0.3856,0.0755,0.5389,0.3856), dim = c(3,3))
CMAQ50aero5_specs = c('SO4', 'CL', 'NA')
CMAQ50aero5_modes = c('I', 'J', 'K')

#' CMAQ v5.0.1 with aero6 and cb05
#' place: CCTM/src/aero/aero6/AERO_DATA.F,v
CMAQ50aero6_split = array(c(-1, -1, -1, -1, -1, -1, -1,
                            0.0776, 0.5538, 0.3086, 0.0368, 0.0114, 0.0118, 0.0,
                            0.0776, 0.5538, 0.0, 0.0, 0.0 ,0.0, 0.3686), 
                          dim = c(7,3))
CMAQ50aero6_specs = c('SO4', 'CL', 'NA', 'MG', 'K', 'CA', 'SEACAT')
CMAQ50aero6_modes = c('I', 'J', 'K')

#' CMAQ v5.0.1 with aero5 and cb05
#' place: CCTM/src/aero/aero5/AERO_DATA.F,v
#' change: I mode is emitted as well!
CMAQ50aero5b_split = array(c(0.0755,0.5389,0.3856,0.0755,0.5389,0.3856,0.0755,0.5389,0.3856), dim = c(3,3))
CMAQ50aero5b_specs = c('SO4', 'CL', 'NA')
CMAQ50aero5b_modes = c('I', 'J', 'K')

#' CMAQ v5.0.1 with aero6 and cb05
#' place: CCTM/src/aero/aero6/AERO_DATA.F,v
#' change: I mode is emitted as well!
CMAQ50aero6b_split = array(c(0.0776, 0.5538, 0.3086, 0.0368, 0.0114, 0.0118, 0.0,
                            0.0776, 0.5538, 0.3086, 0.0368, 0.0114, 0.0118, 0.0,
                            0.0776, 0.5538, 0.0, 0.0, 0.0 ,0.0, 0.3686), 
                          dim = c(7,3))
CMAQ50aero6b_specs = c('SO4', 'CL', 'NA', 'MG', 'K', 'CA', 'SEACAT')
CMAQ50aero6b_modes = c('I', 'J', 'K')

#' my splits fors CMAQ v5.x.x
#' place: here
CMAQmy_split = array(c(0.0776, 0.5538, 0.3086, 0.0368, 0.0114, 0.0118, -1,
                       0.0776, 0.5538, 0.3086, 0.0368, 0.0114, 0.0118, -1,
                       0.0776, 0.5538, -1, -1, -1, -1, 0.3686), 
                     dim = c(7,3))
CMAQmy_specs = c('SO4', 'CL', 'NA', 'MG', 'K', 'CA', 'SEACAT')
CMAQmy_modes = c('I', 'J', 'K')


# hard-coded sea salt emissions from CMAQ ----
cmaqDGNJ = c(0.2651, 0.2677, 0.2696, 0.2713, 0.2736, 0.2752, 0.2768, 0.2784, 0.2806, 0.2823, 0.2840, 0.2858, 0.2883, 0.2903, 0.2924, 0.2951, 0.2974, 0.2998, 0.3028, 0.3054, 0.3080, 0.3113, 0.3140, 0.3174, 0.3203, 0.3232, 0.3267, 0.3297, 0.3332, 0.3363, 0.3394, 0.3430, 0.3462, 0.3499, 0.3533, 0.3573, 0.3611, 0.3652, 0.3700, 0.3752, 0.3806, 0.3871, 0.3945, 0.4030, 0.4129, 0.4246, 0.4259, 0.4271, 0.4284, 0.4298, 0.4311, 0.4328, 0.4342, 0.4356, 0.4371, 0.4385, 0.4401, 0.4416, 0.4434, 0.4451, 0.4467, 0.4484, 0.4501, 0.4518, 0.4538, 0.4556, 0.4575, 0.4594, 0.4613, 0.4633, 0.4655, 0.4676, 0.4697, 0.4718, 0.4740, 0.4764, 0.4787, 0.4811, 0.4835, 0.4859, 0.4886, 0.4912, 0.4938, 0.4965, 0.4994, 0.5022, 0.5051, 0.5081, 0.5112, 0.5143, 0.5175, 0.5208, 0.5242, 0.5276, 0.5312, 0.5348, 0.5386, 0.5424, 0.5463, 0.5503, 0.5544, 0.5587, 0.5631, 0.5675, 0.5722, 0.5769, 0.5818, 0.5867, 0.5919, 0.5972, 0.6026, 0.6083, 0.6140, 0.6201, 0.6263, 0.6325, 0.6392, 0.6458, 0.6529, 0.6600, 0.6676, 0.6751, 0.6833, 0.6914, 0.7001, 0.7088, 0.7177, 0.7276, 0.7372, 0.7478, 0.7582, 0.7690, 0.7810, 0.7928, 0.8050, 0.8187)
cmaqDGNK = c(1.7618, 1.8130, 1.8257, 1.8375, 1.8861, 1.8973, 1.9084, 1.9194, 1.9678, 1.9796, 1.9919, 2.0046, 2.0548, 2.0690, 2.0840, 2.1359, 2.1525, 2.1698, 2.2236, 2.2423, 2.2617, 2.3171, 2.3378, 2.3936, 2.4154, 2.4376, 2.4940, 2.5169, 2.5732, 2.5969, 2.6209, 2.6776, 2.7027, 2.7599, 2.7868, 2.8453, 2.8754, 2.9076, 2.9723, 3.0398, 3.0835, 3.1604, 3.2439, 3.3357, 3.4386, 3.5555, 3.5660, 3.5767, 3.5876, 3.5986, 3.6099, 3.6421, 3.6539, 3.6659, 3.6782, 3.6906, 3.7034, 3.7163, 3.7487, 3.7623, 3.7761, 3.7903, 3.8047, 3.8194, 3.8519, 3.8673, 3.8830, 3.8990, 3.9154, 3.9321, 3.9651, 3.9826, 4.0005, 4.0188, 4.0374, 4.0710, 4.0906, 4.1106, 4.1311, 4.1520, 4.1860, 4.2080, 4.2305, 4.2535, 4.2878, 4.3120, 4.3367, 4.3621, 4.3969, 4.4236, 4.4510, 4.4790, 4.5146, 4.5442, 4.5745, 4.6104, 4.6424, 4.6752, 4.7089, 4.7463, 4.7816, 4.8182, 4.8565, 4.8952, 4.9350, 4.9746, 5.0169, 5.0563, 5.1010, 5.1470, 5.1884, 5.2369, 5.2789, 5.3308, 5.3844, 5.4289, 5.4856, 5.5313, 5.5922, 5.6394, 5.7042, 5.7532, 5.8228, 5.8741, 5.9486, 6.0022, 6.0564, 6.1392, 6.1968, 6.2860, 6.3476, 6.4099, 6.5098, 6.5772, 6.6466, 6.7590)
cmaqSIGJ = c(1.7572, 1.7612, 1.7612, 1.7612, 1.7651, 1.7651, 1.7651, 1.7651, 1.7689, 1.7689, 1.7689, 1.7689, 1.7727, 1.7727, 1.7727, 1.7764, 1.7764, 1.7764, 1.7801, 1.7801, 1.7801, 1.7837, 1.7837, 1.7873, 1.7873, 1.7873, 1.7907, 1.7907, 1.7941, 1.7941, 1.7941, 1.7974, 1.7974, 1.8006, 1.8006, 1.8037, 1.8037, 1.8037, 1.8066, 1.8095, 1.8095, 1.8122, 1.8147, 1.8172, 1.8195, 1.8217, 1.8217, 1.8217, 1.8217, 1.8217, 1.8217, 1.8237, 1.8237, 1.8237, 1.8237, 1.8237, 1.8237, 1.8237, 1.8255, 1.8255, 1.8255, 1.8255, 1.8255, 1.8255, 1.8272, 1.8272, 1.8272, 1.8272, 1.8272, 1.8272, 1.8287, 1.8287, 1.8287, 1.8287, 1.8287, 1.8300, 1.8300, 1.8300, 1.8300, 1.8300, 1.8312, 1.8312, 1.8312, 1.8312, 1.8322, 1.8322, 1.8322, 1.8322, 1.8330, 1.8330, 1.8330, 1.8330, 1.8336, 1.8336, 1.8336, 1.8340, 1.8340, 1.8340, 1.8340, 1.8342, 1.8342, 1.8342, 1.8343, 1.8343, 1.8343, 1.8342, 1.8342, 1.8339, 1.8339, 1.8339, 1.8334, 1.8334, 1.8327, 1.8327, 1.8327, 1.8318, 1.8318, 1.8307, 1.8307, 1.8295, 1.8295, 1.8281, 1.8281, 1.8266, 1.8266, 1.8248, 1.8229, 1.8230, 1.8209, 1.8209, 1.8188, 1.8164, 1.8164, 1.8140, 1.8115, 1.8115)
cmaqSIGK = c(2.1039, 2.0834, 2.0834, 2.0834, 2.0639, 2.0639, 2.0639, 2.0639, 2.0452, 2.0452, 2.0452, 2.0452, 2.0273, 2.0273, 2.0273, 2.0101, 2.0101, 2.0101, 1.9937, 1.9937, 1.9937, 1.9780, 1.9780, 1.9631, 1.9631, 1.9631, 1.9488, 1.9488, 1.9351, 1.9351, 1.9351, 1.9222, 1.9222, 1.9098, 1.9098, 1.8981, 1.8981, 1.8981, 1.8870, 1.8765, 1.8765, 1.8666, 1.8573, 1.8486, 1.8405, 1.8329, 1.8329, 1.8329, 1.8329, 1.8329, 1.8329, 1.8259, 1.8259, 1.8259, 1.8259, 1.8259, 1.8259, 1.8259, 1.8195, 1.8195, 1.8195, 1.8195, 1.8195, 1.8195, 1.8137, 1.8137, 1.8137, 1.8137, 1.8137, 1.8137, 1.8085, 1.8085, 1.8085, 1.8085, 1.8085, 1.8038, 1.8038, 1.8038, 1.8038, 1.8038, 1.7997, 1.7997, 1.7997, 1.7997, 1.7963, 1.7963, 1.7963, 1.7963, 1.7934, 1.7934, 1.7934, 1.7934, 1.7913, 1.7913, 1.7913, 1.7897, 1.7897, 1.7897, 1.7897, 1.7888, 1.7889, 1.7889, 1.7886, 1.7886, 1.7886, 1.7891, 1.7891, 1.7904, 1.7903, 1.7903, 1.7923, 1.7924, 1.7952, 1.7952, 1.7952, 1.7988, 1.7989, 1.8034, 1.8034, 1.8089, 1.8090, 1.8155, 1.8154, 1.8230, 1.8230, 1.8318, 1.8417, 1.8417, 1.8529, 1.8529, 1.8656, 1.8799, 1.8799, 1.8960, 1.9138, 1.9138)
cmaqFNJ = c(89.326, 89.524, 89.524, 89.524, 89.709, 89.709, 89.709, 89.709,89.881, 89.881, 89.881, 89.881, 90.040, 90.040, 90.040, 90.188,90.188, 90.188, 90.325, 90.324, 90.324, 90.451, 90.451, 90.569,90.569, 90.569, 90.678, 90.678, 90.779, 90.779, 90.779, 90.873,90.873, 90.959, 90.959, 91.039, 91.039, 91.039, 91.113, 91.181,91.181, 91.243, 91.301, 91.353, 91.401, 91.445, 91.445, 91.445,91.445, 91.445, 91.445, 91.484, 91.484, 91.484, 91.484, 91.484,91.484, 91.484, 91.520, 91.520, 91.520, 91.520, 91.520, 91.520,91.551, 91.551, 91.551, 91.551, 91.551, 91.551, 91.579, 91.579,91.579, 91.579, 91.579, 91.604, 91.604, 91.604, 91.604, 91.604,91.625, 91.625, 91.625, 91.625, 91.642, 91.642, 91.642, 91.642,91.656, 91.656, 91.656, 91.656, 91.667, 91.667, 91.667, 91.675,91.675, 91.675, 91.675, 91.679, 91.679, 91.679, 91.680, 91.680,91.680, 91.678, 91.678, 91.672, 91.672, 91.672, 91.663, 91.663,91.650, 91.650, 91.650, 91.633, 91.633, 91.612, 91.612, 91.587,91.587, 91.558, 91.558, 91.524, 91.524, 91.485, 91.441, 91.441,91.392, 91.392, 91.337, 91.274, 91.274, 91.205, 91.129, 91.129)
cmaqFNK = c(11.315, 11.110, 11.110, 11.109, 10.919, 10.919, 10.919, 10.919, 10.740, 10.740, 10.740, 10.740, 10.573, 10.573, 10.573, 10.417, 10.417, 10.417, 10.270, 10.271, 10.271, 10.134, 10.134, 10.006, 10.006, 10.006, 9.886, 9.886, 9.774, 9.774, 9.774, 9.669, 9.669, 9.571, 9.571, 9.480, 9.480, 9.480, 9.395, 9.315, 9.315, 9.243, 9.174, 9.111, 9.053, 8.999, 8.999, 8.999, 9.000, 9.000, 9.000, 8.951, 8.951, 8.951, 8.951, 8.951, 8.951, 8.951, 8.907, 8.907, 8.907, 8.907, 8.907, 8.907, 8.867, 8.867, 8.867, 8.867, 8.867, 8.867, 8.832, 8.832, 8.832, 8.832, 8.832, 8.800, 8.800, 8.800, 8.800, 8.800, 8.773, 8.773, 8.773, 8.773, 8.751, 8.751, 8.751, 8.751, 8.732, 8.732, 8.732, 8.732, 8.718, 8.718, 8.718, 8.708, 8.708, 8.708, 8.708, 8.702, 8.703, 8.703, 8.701, 8.701, 8.701, 8.704, 8.704, 8.712, 8.712, 8.711, 8.724, 8.725, 8.742, 8.742, 8.742, 8.765, 8.765, 8.794, 8.794, 8.828, 8.828, 8.869, 8.869, 8.915, 8.915, 8.970, 9.031, 9.031, 9.101, 9.101, 9.179, 9.268, 9.268, 9.366, 9.476, 9.476)

cmaqRH = c(0.45, 0.46, 0.47, 0.48, 0.49, 0.5, 0.51, 0.52, 0.53, 0.54, 0.55, 0.56, 0.57, 0.58, 0.59, 0.6, 0.61, 0.62, 0.63, 0.64, 0.65, 0.66, 0.67, 0.68, 0.69, 0.7, 0.71, 0.72, 0.73, 0.74, 0.75, 0.76, 0.77, 0.78, 0.79, 0.8, 0.81, 0.82, 0.83, 0.84, 0.85, 0.86, 0.87, 0.88, 0.89, 0.9, 0.901, 0.902, 0.903, 0.904, 0.905, 0.906, 0.907, 0.908, 0.909, 0.91, 0.911, 0.912, 0.913, 0.914, 0.915, 0.916, 0.917, 0.918, 0.919, 0.92, 0.921, 0.922, 0.923, 0.924, 0.925, 0.926, 0.927, 0.928, 0.929, 0.93, 0.931, 0.932, 0.933, 0.934, 0.935, 0.936, 0.937, 0.938, 0.939, 0.94, 0.941, 0.942, 0.943, 0.944, 0.945, 0.946, 0.947, 0.948, 0.949, 0.95, 0.951, 0.952, 0.953, 0.954, 0.955, 0.956, 0.957, 0.958, 0.959, 0.96, 0.961, 0.962, 0.963, 0.964, 0.965, 0.966, 0.967, 0.968, 0.969, 0.97, 0.971, 0.972, 0.973, 0.974, 0.975, 0.976, 0.977, 0.978, 0.979, 0.98, 0.981, 0.982, 0.983, 0.984, 0.985, 0.986, 0.987, 0.988, 0.989, 0.99)

# Dcut was calculated by calc_intersect(cmaqDGNJ, cmaqDGNK, cmaqSIGJ, cmaqSIGK, cmaqFNJ, cmaqFNK)
cmaqDJKcut_RH = c(0.9733300,0.9931762,1.0002055,1.0065636,1.0253434,1.0313600,1.0373646,1.0433571,1.0619879,1.0684070,1.0748874,1.0817093,1.1016666,1.1093022,1.1173310,1.1382075,1.1470727,1.1563205,1.1785785,1.1886234,1.1987831,1.2222700,1.2329512,1.2569815,1.2684568,1.2799862,1.3044443,1.3164224,1.3410494,1.3534926,1.3659777,1.3910988,1.4040940,1.4296401,1.4435438,1.4702086,1.4858212,1.5026260,1.5325787,1.5642715,1.5867775,1.6236187,1.6640832,1.7091908,1.7600568,1.8185113,1.8240176,1.8292607,1.8347960,1.8406768,1.8463104,1.8616118,1.8676366,1.8736936,1.8800937,1.8862150,1.8929904,1.8994869,1.9148132,1.9220294,1.9289832,1.9362967,1.9436425,1.9510370,1.9668032,1.9746244,1.9827894,1.9910033,1.9992826,2.0079056,2.0239770,2.0330440,2.0421768,2.0513753,2.0609179,2.0773533,2.0873736,2.0977547,2.1082185,2.1187484,2.1358494,2.1471692,2.1585721,2.1703529,2.1875916,2.1998835,2.2125535,2.2256350,2.2431228,2.2567315,2.2707523,2.2851681,2.3030964,2.3180880,2.3337862,2.3518094,2.3683922,2.3851098,2.4022735,2.4211275,2.4390957,2.4579315,2.4776718,2.4971590,2.5177151,2.5378258,2.5593893,2.5792868,2.6021420,2.6255469,2.6464577,2.6713285,2.6924409,2.7190987,2.7463356,2.7683877,2.7975645,2.8200233,2.8510416,2.8744743,2.9075382,2.9313487,2.9669210,2.9920640,3.0298081,3.0555582,3.0811926,3.1238162,3.1506915,3.1960097,3.2249975,3.2536223,3.3043753,3.3357636,3.3674472,3.4246533)



# boundaries for integrating emissions parameterisations ----
go03DMin_dry = 0.03
go03DJKcut_RH = cmaqDJKcut_RH # calculated from CMAQ log-normal distributions
go03DMax_dry = 5

sp13DMin_dry = 0.02   # given in SP13 publication
sp13DIJcut_dry = 0.08 # just chosen!
sp13DJKcut_RH = cmaqDJKcut_RH # calculated from CMAQ log-normal distributions
sp13DMax_dry = 30     # given in SP13 publication

ma03D01_dry = 0.02   # given in MA03 publication
ma03D12_dry = 0.145 # given in MA03 publication
ma03D23_dry = 0.419 # given in MA03 publication
ma03D30_dry = 2.8    # given in MA03 publication
mo86Dmax_dry = 8    # given in SP13 publication
sm93Din_dry = 5    # given in SP13 publication
sm93Dmax_dry = 30    # given in SP13 publication

ov14DMin_dry = 0.01   # guessed from plots in OV14
ov14DIJcut_dry = 0.1  # just chosen!
ov14DJKcut_RH = cmaqDJKcut_RH # calculated from CMAQ log-normal distributions
ov14DJKcut_dry = sum(cmaqDJKcut_RH[-1] * (cmaqRH[-1] - cmaqRH[-136])) / (cmaqRH[136]-cmaqRH[1]) # weighted mean from cmaqDJKcut_RH
ov14DMax_dry = 9.5    # from Ov13 paper, section 3.2, coarse particles between 0.17 and 9.5 mu m measuered



# parameters for MA03 parameterisation ---- 
constMA03_a = (array(c(-2.5761655*10^35, -2.4522893*10^33,  1.0851561*10^29, 
                       5.9324436*10^28,  2.4035441*10^27, -9.8414340*10^23,
                       -2.8661743*10^21, -8.1478341*10^20,  3.1323593*10^18, 
                       -3.0029837*10^13,  1.1828503*10^14, -4.1645326*10^12,
                       -2.8808135*10^6 , -6.7429939*10^6 ,  2.1806374*10^6), dim = c(3,5))
               * array(rep(10^(6*(-4:0)), each = 3), dim = c(3,5)))
constMA03_b = (array(c( 7.1884656*10^37,  7.3683150*10^35, -2.8594762*10^31, 
                        -1.6156647*10^31, -7.3102149*10^29,  2.6012137*10^26,
                        6.7913299*10^23,  2.5283404*10^23, -8.2974644*10^20, 
                        1.8289469*10^16, -3.7872729*10^16,  1.1046678*10^15,
                        7.6092681*10^8 ,  2.2794005*10^9 , -5.8003880*10^8), dim = c(3,5))
               * array(rep(10^(6*(-4:0)), each = 3), dim = c(3,5)))





# create name space for all paths ----
namespace = list()
for (iType in c('BSH', 'WAVE', 'MC2D', 'MC3D', 'OCEAN', 'COORD', 'BASE', 'OUT')) { 
  namespace[[iType]] = list()
}

namespace$BASE$IN1 = dBASEIN1
namespace$BASE$IN2 = dBASEIN2
namespace$BASE$OUT = dBASEOUT

namespace$BSH$var_sst = 'SST'
namespace$BSH$var_sal = 'SALINITY'
namespace$WAVE$var_swh = 'hs'
namespace$WAVE$var_fv = 'FV'

namespace$OCEAN = list('nSZ'=list(), 'wSZ'=list(),
                       'nSZnSL'=list(), 'nSZwSL'=list(),
                       'wSZnSL'=list(), 'wSZwSL'=list())

namespace = set_namesspace(namespace, GRID_NAME, strDummyDate)
