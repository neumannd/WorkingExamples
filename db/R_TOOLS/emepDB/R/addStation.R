#' Adds a new station to the EMEP database
#' 
#' Adds a new station to the EMEP database
#' 
#' The structure of 'station' should be: list(station_id, station_name, country, longitude, latitude, altitude)
#' 
#' @param station list(): list with information on the station to insert; station_id needs to be a 7-character string
#' @return list(err_code, err_string): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export
addStation = function(station) {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = addStation.RODBC(channel, station)
  close(channel)
  
  return(return_val)
  
}
