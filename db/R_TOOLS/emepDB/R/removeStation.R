#' Removes a station from the EMEP database
#' 
#' @param station_id character: station id of the station to remove; is unambiguous; is optional if station_name is set;
#' @param station_name character (optional): name of the station(s) to remove; might be ambiguous; obligatory if no station_id is set;
#' @return list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export
removeStation = function(station_id = '', station_name = '') {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = removeStation.RODBC(channel, station_id, station_name)
  close(channel)
  
  return(return_val)
  
}
