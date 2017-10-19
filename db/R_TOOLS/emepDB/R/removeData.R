#' private: remove rows from data table
#'
#' Removes all rows from the data table which have a given sf_id. Prior to 
#' sending the DELETE query, the presence of data row with this sf_id is
#' tested.
#'
#' @param sf_id integer: id of an entry in the f_substances table
#' @return list(err_code, n_rows) list(integer, integer): !=0 if an error occured; number of removed rows
#' @author Daniel Neumann, daniel.neumann@___.de
#' @format R Code
removeData = function(sf_id) {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = removeData.RODBC(channel, sf_id)
  close(channel)
  
  return(return_val)
}
