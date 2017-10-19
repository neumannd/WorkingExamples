#' Adds a new station to the EMEP database
#' 
#' Adds a new station to the EMEP database
#' 
#' The structure of 'station' should be: list(station_id, station_name, country, longitude, latitude, altitude)
#' 
#' @param channel RODBC: open RODBC database connection
#' @param station list(station_id, station_name, country, longitude, latitude, altitude): list with information on the station to insert; station_id needs to be a 7-character string
#' @return list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export
addStation.RODBC = function(channel, station) {
  
  if (class(station) != 'list') stop("'station' has wrong format.")
  
  # verify station_id ----
  if (is.null(station$station_id)) {
    if (is.null(station$id)) stop('addStation: neither station$station_id nor station$id parsed')
    else station$station_id = station$id
    warning('addStation: station$station_id not existing; using station$id instead;')
  }
  
  verified_station_id = verifyStationId(station$station_id)
  str_station_id = paste("'", verified_station_id$station_id, "'", sep = '')
  
    
  # verify station_name ----
  if (is.null(station$station_name)) {
    if (is.null(station$name)) stop('addStation: neither station$station_name nor station$name parsed')
    else station$station_name = station$name
    warning('addStation: station$station_name not existing; using station$name instead;')
  }
  str_station_name = paste("'", station$station_name, "'", sep = '')
  
  
  # verify country ----
  if (is.null(station$country)) {
    station$country = substr(station_id, 2, 3)
    warning('addStation: station$country not existing; using first 2 characters of station$station_id instead;')
  }
  str_country = paste("'", station$country, "'", sep = '')
  
  
  # verify longitude ----
  if (is.null(station$longitude)) {
    if (is.null(station$lon)) stop('addStation: neither station$longitude nor station$lon existing')
    else station$longitude = station$lon
    warning('addStation: station$longitude not existing; using station$lon instead;')
  }
  
  
  # verify latitude ----
  if (is.null(station$latitude)) {
    if (is.null(station$lat)) stop('addStation: neither station$latitude nor station$lat existing')
    station$latitude = station$lat
    warning('addStation: station$latitude not existing; using station$lat instead;')
  }
  
  
  # test whether station already exists ----
  test_station_id = sqlQuery(channel, paste("SELECT * FROM stations WHERE station_id = ", str_station_id, ";", sep = ""))
  test_station_name = sqlQuery(channel, paste("SELECT * FROM stations WHERE station_name = ", str_station_name, ";", sep = ""))
  
  if (dim(test_station_id)[1] != 0) {
    returnInsert = 'addStation: Inserting no station because station with the same station_id does already exist.'
    stop(returnInsert)
    return_value = 1
  } else if (dim(test_station_name)[1] > 0) {
    warning('addStation: Station with the same station_name does already exist but station_id is different. Therefore, station is inserted.')
  }
  
  
  if (dim(test_station_id)[1] == 0) {
    # insert data ----
    # create insert string
    insertString = paste("INSERT INTO stations",
                         "(station_id, station_name, country, longitude, latitude, altitude)",
                         " VALUES(",
                         str_station_id, ", ", str_station_name, ", ", str_country, ", ",
                         station$longitude, ", ", station$latitude, ", ", station$altitude, ");", 
                         sep="")
    # print it
    print(insertString)
    
    # perform insertion
    returnInsert <- sqlQuery(channel, query=insertString)
    
    # give user feedback
    if (length(returnInsert) == 0) {
      print('Insertion was performed without errors.')
      return_value = 0
    } else {
      print(returnInsert)
      stop('addStation: an error was thrown during insertion into the database')
      return_value = 1
    }
  }
  
  
  return(list('err_code' = return_value, 'err_string' = returnInsert))
}
