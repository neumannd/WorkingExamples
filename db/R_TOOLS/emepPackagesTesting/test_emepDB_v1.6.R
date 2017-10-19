library('emepDB')

setwd('/home/neumannd/TMP/emep_tools/package/emepPackagesTesting/emep_data')


# set DBaccess variable ----
#' needed for database functions which do not need an RODBC connection to be parsed
#' (all functions not containing RODBC in their name)
DBaccess <- list(name="neumannd-emep04", uid="***", pwd="***") 


# establish database connection ----
#' needed for *.RODBC() functions
myCon <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 


# tests ----
test_addStation = FALSE
test_verifyStationId = FALSE
test_removeStation = FALSE
test_addFlag = FALSE
test_removeFlag = FALSE
test_addFile = TRUE



# structure of some lists to parse ----
## structure of station
# myStation = list('station_name' = 'Geest',
#                 'station_id' = 1234568,
#                 'country' = 'DE',
#                 'longitude' = 52+17/60,
#                 'latitude' = 8+3/60,
#                 'altitude' = 0.0)

## structure of flag:
# flag = list(numflag = 145, status = 'V', description = 'test', flaggroup = 12, group_description = 'test2')


# insert station ----
if (test_addStation) {
  cat('\n~~~~~~~~~~~~\n INSERTING STATIONS\n~~~~~~~~~~~~\n')
  cat('SHOULD WORK: Insert a new station via addStation() [Function return value not captured]\n')
  myStation = list('station_name' = 'Geesthacht',
                   'station_id' = 'DE9989R',
                   'country' = 'DE',
                   'longitude' = 52+17/60,
                   'latitude' = 8+3/60,
                   'altitude' = 0.0)
  addStation(myStation)
  
  cat('SHOULD WORK: Insert another new station via addStation() [only station_id differs] \n')
  myStation = list('station_name' = 'Geesthacht',
                   'station_id' = 'DE9988R',
                   'country' = 'DE',
                   'longitude' = 52+17/60,
                   'latitude' = 8+3/60,
                   'altitude' = 0.0)
  addStation(myStation)
  
  cat('SHOULD NOT WORK: Insert another new station via addStation() [station_id already exists] \n')
  myStation = list('station_name' = 'Osnabrueck',
                   'station_id' = 'DE9988R',
                   'country' = 'DE',
                   'longitude' = 52+17/60,
                   'latitude' = 8+3/60,
                   'altitude' = 0.0)
  addStation(myStation)
  
  cat('SHOULD WORK: Insert another new station via addStation() [previous station; but new station_id] \n')
  myStation = list('station_name' = 'Osnabrueck',
                   'station_id' = 'DE9987R',
                   'country' = 'DE',
                   'longitude' = 52+17/60,
                   'latitude' = 8+3/60,
                   'altitude' = 0.0)
  addStation(myStation)
  
  cat('SHOULD WORK: Insert another new station via addStation.RODBC() [manually opened database connection] \n')
  myStation = list('station_name' = 'Geesthacht',
                   'station_id' = 'DE9986R',
                   'country' = 'DE',
                   'longitude' = 52+17/60,
                   'latitude' = 8+3/60,
                   'altitude' = 0.0)
  addStation.RODBC(myCon, myStation)
}


# test station_id ----
if (test_verifyStationId) {
  cat('\n~~~~~~~~~~~~\n WHICH STATION IDs ARE VALID?\n~~~~~~~~~~~~\n')
  cat('SHOULD WORK: test station_id with verifyStationId() [EMEP format] \n')
  myId = 'DE0001R'
  cat(paste('  test station_id: ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # VALID
  cat(paste("  returned string: '", catchReturn$station_id, "'\n\n", sep = ''))
  
  cat('SHOULD WORK: test station_id with verifyStationId() [7 characters -> OK] \n')
  myId = 'sfgsdg3'
  cat(paste('  test station_id: ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # VALID
  cat(paste("  returned string: '", catchReturn$station_id, "'\n\n", sep = ''))
  
  cat('SHOULD WORK: test station_id with verifyStationId() [less than 7 characters -> OK] \n')
  myId = 'Dsd2'
  cat(paste('  test station_id: ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # VALID
  cat(paste("  returned string: '", catchReturn$station_id, "'\n\n", sep = ''))
  
  cat('SHOULD NOT WORK: test station_id with verifyStationId() [more than 7 characters -> not OK] \n')
  myId = 'DE0001Ra'
  cat(paste('  test station_id: ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # INVALID
  
  
  cat('SHOULD WORK: test station_id with verifyStationId() [7-digits integer -> OK] \n')
  myId = 1234567
  cat(paste('  test station_id (integer): ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # VALID
  cat(paste("  returned string: '", catchReturn$station_id, "'\n\n", sep = ''))
  
  cat('SHOULD NOT WORK: test station_id with verifyStationId() [integer with more than 7 digits -> not OK] \n')
  myId = 12345678
  cat(paste('  test station_id (integer): ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # INVALID
  
  cat('SHOULD WORK: test station_id with verifyStationId() [integer with less than 7 characters -> OK] \n')
  myId = 123456
  cat(paste('  test station_id (integer): ', myId, sep = ''))
  catchReturn = verifyStationId(myId) # VALID, but: space to the left!!!
  cat(paste("  returned string: '", catchReturn$station_id, "'\n\n", sep = ''))
}


# remove stations ----
if (test_removeStation) {
  cat('\n~~~~~~~~~~~~\n DELETING STATIONS\n~~~~~~~~~~~~\n')
  cat('SHOULD WORK: remove station (station_id = DE9987R) with removeStation() \n')
  catchReturn = removeStation(myCon,station_id = 'DE9987R')
  
  cat('SHOULD NOT WORK: remove station (station_id = DE9987R) with removeStation() [was already removed before] \n')
  catchReturn = removeStation(myCon,station_id = 'DE9987R')
  
  cat('SHOULD NOT WORK: remove station (station_id = DE333R) with removeStation() [station_id did never exist] \n')
  catchReturn = removeStation(myCon,station_id = 'DE333R')
  
  cat('SHOULD WORK: remove station (station_id = DE9989R) with removeStation.RODBC() [own RODBC connection] \n')
  catchReturn = removeStation.RODBC(myCon,station_id = 'DE9989R')
  
  cat('SHOULD WORK: remove station  by name (station_name = Geesthacht) with removeStation() [remove more than one station] \n')
  catchReturn = removeStation(myCon,station_name = 'Geesthacht')
}


# insert flags ----
cat('\n~~~~~~~~~~~~\n INSERTING FLAGS\n~~~~~~~~~~~~\n')
if (test_addFlag) {
  cat('SHOULD WORK: Insert a flag via addFlag.RODBC (create new group)\n')
  flag = list(numflag = 975, status = 'V', description = 'test', flaggroup = 12, group_description = 'test2')
  test = addFlag.RODBC(myCon, flag,  no_insert_on_warning = TRUE, create_group = TRUE)
  cat('\nSHOULD WORK: Insert a flag via addFlag (existing group)\n')
  flag = list(numflag = 977, status = 'V', description = 'test', flaggroup = 1, group_description = 'test2')
  test = addFlag(flag,  no_insert_on_warning = TRUE, create_group = TRUE)
  cat('\nSHOULD NOT WORK: Insert a flag via addFlag.RODBC (create new group; wrong parameters)\n')
  flag = list(numflag = 976, status = 'V', description = 'test', flaggroup = 14)
  test = addFlag.RODBC(myCon, flag,  no_insert_on_warning = TRUE, create_group = TRUE)
  cat('\nSHOULD NOT WORK: Insert a flag via addFlag.RODBC (create new group; wrong parameters)\n')
  flag = list(numflag = 976, status = 'V', description = 'test', flaggroup = 14, group_description = 'test2')
  test = addFlag.RODBC(myCon, flag,  no_insert_on_warning = TRUE)
  cat('\nSHOULD WORK: Insert a flag via addFlag.RODBC (insert into group created by first addFlag.RODBC call)\n')
  flag = list(numflag = 976, status = 'V', description = 'test', flaggroup = 12)
  test = addFlag.RODBC(myCon, flag,  no_insert_on_warning = TRUE)
}


# delete flags ----
if (test_removeFlag) {
  cat('\n~~~~~~~~~~~~\n DELETING FLAGS\n~~~~~~~~~~~~\n')
  cat('\nSHOULD WORK: delete a flag via removeFlag.RODBC \n')
  test = removeFlag.RODBC(myCon, 976)
  cat('\nSHOULD WORK: delete a flag via removeFlag \n')
  test = removeFlag.RODBC(myCon, 975)
  cat('\nSHOULD NOT WORK: delete a flag via removeFlag.RODBC (wrong flag) \n')
  test = removeFlag.RODBC(myCon, 975)
  cat('\nSHOULD WORK: delete a flag via removeFlag.RODBC \n')
  test = removeFlag.RODBC(myCon, 977)
  cat('\n delete all flags and flag group, which were created before (not part of the test)\n')
  print(sqlQuery(myCon, "DELETE FROM flags WHERE flaggroup = 12;"))
  print(sqlQuery(myCon, "DELETE FROM flaggroups WHERE flaggroup = 12;"))
}



# insert EMEP files ----
if (test_addFile) {
  cat('\n~~~~~~~~~~~~\n ADDING EMEP DATA\n~~~~~~~~~~~~\n')
  cat('\nSHOULD WORK: add a EMEP file with addFile() \n')
  catchOutput = addFile('TT/TT00001R.good.nas')
  
  cat('\nSHOULD WORK: add another EMEP file with addFile.RODBC() \n')
  catchOutput = addFile.RODBC(myCon, 'TT/TT00002R.good.nas')
  
  cat('\nSHOULD PARTLY WORK: add another EMEP file with addFile() \n[one numflag is wrong; therefore, 13 of 14 variables are completely inserted and 1 of 14 not] \n')
  catchOutput = addFile('TT/TT00003R.half.nas')
  
  cat('\nSHOULD WORK: adds a corrected version of the EMEP file a second time with addFile() [13 of 14 data sets are untouched; 1 data set is removed and newly inserted] \n')
  catchOutput = addFile('TT/TT00004R.good.nas')
  
  cat("\nSHOULD NOT WORK: adds a file containing variables with the 'Statistics' attribute set with addFile(..., removeStatistics=FALSE, ...) [stop due to problematic attributes; default is TRUE] \n")
  catchOutput = addFile('TT/TT00006R.bad.nas.nas', removeStatistics = FALSE) # TODO
  
  cat("\nSHOULD WORK: adds a file containing variables with the 'Statistics' attribute set with addFile(..., removeStatistics=TRUE, ...) [some variables with statistical data != 'arithmetic mean' are removed; default is TRUE] \n")
  catchOutput = addFile('TT/TT00006R.bad.nas.nas') 
  
  cat("\nSHOULD NOT WORK: adds a file containing variables with the 'Statistics' and 'Fraction' attribute set with addFile(..., forceCleanAndInsertProblematicFiles=FALSE, ...) [stop due to the presence of the Fractions attribute; default is TRUE] \n")
  catchOutput = addFile('TT/TT00007R.bad.nas')
  
  cat("\nSHOULD WORK: adds a file containing variables with the 'Statistics' and 'Fraction' attribute set with addFile(..., forceCleanAndInsertProblematicFiles=TRUE, ...) [removes variables with the Fraction attribute; default is TRUE] \n")
  catchOutput = addFile('TT/TT00007R.bad.nas', forceCleanAndInsertProblematicFiles = TRUE)
  
  cat("\nSHOULD NOT WORK: adds a file containing variables with the 'Statistics' and 'Fraction' attribute set with addFile(..., forceCleanAndInsertProblematicFiles=TRUE, ...) [no variables are left after removing the Fractions attribute] \n")
  catchOutput = addFile('TT/TT00008R.bad.nas', forceCleanAndInsertProblematicFiles = TRUE)
}



# close RODBC connection ----
close(myCon)
