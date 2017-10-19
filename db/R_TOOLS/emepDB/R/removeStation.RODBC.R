#' Removes a station from the EMEP database
#' 
#' @param channel RODBC: open RODBC database connection
#' @param station_id character: station id of the station to remove; is unambiguous; is optional if station_name is set;
#' @param station_name character (optional): name of the station(s) to remove; might be ambiguous; obligatory if no station_id is set;
#' @return list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export
removeStation.RODBC = function(channel, station_id = '', station_name = '') {
  
  return_value = 0
  station_case = 0
  # station_case:
  #  1: use only station_id
  #  2: use only station_name
  #  3: use station_id and station_name
  
  # do some input data test ----
  if(station_id == '') {
    if (station_name == '') {
      stop('removeStation: neither station_id nor station_name were set')
    } else {
      warning('removeStation: station_id not defined; using station_name instead; station_name might be ambiguous and remove more than one station;')
      station_case = 2
      str_station_name = paste("'", station_name, "'", sep = '')
    }
  } else {
    verified_station_id = verifyStationId(station_id)
    str_station_id = paste("'", verified_station_id$station_id, "'", sep = '')
    if (station_name == '') station_case = 1
    else {station_case = 3; str_station_name = paste("'", station_name, "'", sep = '')}
  }
  
  
  # test whether station already exists ----
  test_station_id = array(0.0, dim = c(0,6))
  test_station_name = array(0.0, dim = c(0,6))
  test_station_id_name = array(0.0, dim = c(0,6))
  if(station_case == 1 || station_case == 3) test_station_id = sqlQuery(channel, paste("SELECT * FROM stations WHERE station_id = ", str_station_id, ";", sep = ""))
  if(station_case == 2 || station_case == 3) test_station_name = sqlQuery(channel, paste("SELECT * FROM stations WHERE station_name = ", str_station_name, ";", sep = ""))
  if(station_case == 3) test_station_id_name = sqlQuery(channel, paste("SELECT * FROM stations WHERE station_name = ", str_station_name, " AND station_id = ", str_station_id, ";", sep = ""))
  
  if ((station_case == 1 || station_case == 3) && dim(test_station_id)[1] == 0) {
    returnDelete = paste('removeStation: No station with station_id ', str_station_id, ' exists.', sep = '')
    warning(returnDelete)
    return_value = 1
  }
  if ((station_case == 2 || station_case == 3) && dim(test_station_name)[1] == 0) {
    returnDelete = paste('removeStation: No station with station_name ', str_station_name, ' exists.', sep = '')
    warning(returnDelete)
    return_value = 1
  }
  if(station_case == 3 && dim(test_station_id_name)[1] == 0 && (dim(test_station_id)[1] != 0) && (dim(test_station_name)[1] != 0)) {
    returnDelete = paste('removeStation: Stations with station_name ', str_station_name, ' or station_id ', str_station_id, ' exist but no station with both values.', sep = '')
    warning(returnDelete)
    return_value = 1
  }
  
  
  # deleting data ----
  if (return_value == 0) {
    # create delete string
    if(station_case == 1) {
      numberString = paste('Trying to delete ', formatC(dim(test_station_id)[1], format = 'd'), ' stations.', sep = '')
      deleteString = paste("DELETE FROM stations WHERE station_id = ", str_station_id, ";", sep = '')
    } else if (station_case == 2) {
      numberString = paste('Trying to delete ', formatC(dim(test_station_name)[1], format = 'd'), ' stations.', sep = '')
      deleteString = paste("DELETE FROM stations WHERE station_name = ", str_station_name, ";", sep = '')
    } else if (station_case == 3) {
      numberString = paste('Trying to delete ', formatC(dim(test_station_id_name)[1], format = 'd'), ' stations.', sep = '')
      deleteString = paste("DELETE FROM stations WHERE station_id = ", str_station_id, " AND station_name = ", str_station_name, ";", sep = '')
    }
    
    # print it
    print(numberString)
    print(deleteString)
    
    # perform deletion
    returnDelete <- sqlQuery(channel, query=deleteString)
    
    # give user feedback
    if (length(returnDelete) == 0) {
      print('Deletion was performed without errors.')
      return_value = 0
    } else {
      warning('removeStation: an error was thrown during deletion from the database')
      print(returnDelete)
      return_value = 1
    }
  }
  
  return(list('err_code' = return_value, 'err_string' = returnDelete))
}
