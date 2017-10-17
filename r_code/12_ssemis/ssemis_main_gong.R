#' ssemis_main_gong
#' 
#' This script is part of a sea salt emissions calculation programme. The programme
#' calculates sea salt emissions according to the sea salt emission function by 
#' Gong (2003).
#' 
#' @author Daniel Neumann
#' @date 2015-Nov-06
#' @version 4.0.1
#' 
#' References:
#'  Gong, S. L. A parameterization of sea-salt aerosol source function for 
#'  sub- and super-micron particles Global Biogeochem. Cycles, 2003, 17, 7.
#'  doi: 10.1029/2003GB002079
#'  


# Load libraries and external functions ----
source('ssemis_calc_go03.R')


# get command line arguments ----
myArgs = ssemis_read_args(commandArgs(trailingOnly = TRUE))


# set parameters ----
if ('GRID_NAME'%in%myArgs$args.valid.names) {
  GRID_NAME = myArgs$args.valid.list[['GRID_NAME']]
} else {
  GRID_NAME = 'CD72'
  # GRID_NAME = 'CD24'
  # GRID_NAME = 'CD06'
}
grid_name = tolower(GRID_NAME)


# choose time ----
if ('FROM'%in%myArgs$args.valid.names && 'TO'%in%myArgs$args.valid.names) {
  myDates = as.integer(myArgs$args.valid.list[['FROM']]):as.integer(myArgs$args.valid.list[['TO']])
} else {
  myDates = c(2008001)
  # myDates = c(2008001:2008365)
}

if ('MODE'%in%myArgs$args.valid.names) {
  myMode = as.integer(myArgs$args.valid.list[['MODE']])
} else myMode = 1
if ('AERO'%in%myArgs$args.valid.names) {
  myAero = as.integer(myArgs$args.valid.list[['AERO']])
} else myAero = 5
if ('CMAQ'%in%myArgs$args.valid.names) {
  myCMAQ = as.numeric(myArgs$args.valid.list[['CMAQ']])
} else myCMAQ = 5.0
if ('SURF'%in%myArgs$args.valid.names) {
  surfzone = as.logical(myArgs$args.valid.list[['SURF']])
} else surfzone = TRUE

# Note: We append a 'b'. This 'b' indicates that we will not employ the normal
#       CMAQ mass split (J and K mode) but that we employ a modified version
#       which employs I mode emissions as well.
myCMAQaeroBase = paste('CMAQ', formatC(myCMAQ*10, format = 'd'), 'aero', formatC(myAero, format = 'd', width = 1), 'b', sep = '')
if(surfzone) surftype = 'wSZ' else surftype = 'nSZ'

#' get grid description
gridDesc = get_griddesc(GRID_NAME) # get grid description


# Main program ----


#' iteratre all dates
for (iDate in myDates) {
  strDate = formatC(iDate, format = 'd', width = 7)
  
  # set files ---- 
  namespace = set_namesspace(namespace, GRID_NAME, strDate, 'go03', myMode, 
                               surftype, 'wSL', paste('ae', formatC(myAero, format='d', width = 1), sep = ''))
  
  
  # integrate source function ----
  print('Start integrating')
  print(namespace$OCEAN$path)
  print(paste('date: ', iDate, '; grid: ', GRID_NAME, sep = ''))
  tmpReturn = ssemis_calc_go03(iDate, gridDesc, namespace, modeIntegration = myMode, surfzone = surfzone)
  print('Finished with integrating')
  
  tmpSSEMIS = tmpReturn$SSEMIS
  tmpUNITS = tmpReturn$UNITS
  
  
  # calculate mass emissions ----
  tmpMassSplit = split_ssemis(tmpSSEMIS$MASS, tmpUNITS$MASS, 
                              get(paste(myCMAQaeroBase, 'split', sep = '_')), 
                              get(paste(myCMAQaeroBase, 'specs', sep = '_')), 
                              get(paste(myCMAQaeroBase, 'modes', sep = '_')))
  
  
  # copy into output variables ----
  #' put all data from tmpSSEMIS and valSSEMISmassSplit into valSSEMIS as list
  #' copy mass emissions
  valSSEMIS = tmpMassSplit$SSEMIS
  valUNITS = tmpMassSplit$UNITS
  
  #' copy number emissions
  myNames = names(tmpSSEMIS$NUM)
  for (i1 in 1:length(myNames)) {
    myNameOld = myNames[i1]
    myNameNew = paste('NUM', modeNameShort[myNameOld==modeNumb], sep = "")
    valSSEMIS[[myNameNew]] = tmpSSEMIS$NUM[[myNameOld]]
    valUNITS[[myNameNew]] = tmpUNITS$NUM
  }
  
  #' copy surface emissions
  myNames = names(tmpSSEMIS$SRF)
  for (i1 in 1:length(myNames)) {
    myNameOld = myNames[i1]
    myNameNew = paste('SRF', modeNameShort[myNameOld==modeNumb], sep = "")
    valSSEMIS[[myNameNew]] = tmpSSEMIS$SRF[[myNameOld]]
    valUNITS[[myNameNew]] = tmpUNITS$SRF
  }
  
  
  # write out results ----
  #' write results out into a file
  writeSuccess = write_ssemis(gridDesc, iDate, namespace, 0, valSSEMIS, valUNITS)
  
  
  # finalise ----
  #' remove large arrays and force the garbage collector to run
  rm(tmpReturn, tmpSSEMIS, tmpUNITS, tmpMassSplit, valSSEMIS, valUNITS)
  gc()
}

print('finished')
