#' private: set a row in the f_substance table as 'complete'
#' 
#' Sets the 'complete' boolean of one entry in table 'f_substances'
#' to TRUE. Returns whether it was successful or not. Does not test
#' whether an entry exists, in advance. A connection to 
#' the database defined by the variable DBaccess is established.
#' The function existsFSubstance.RODBC does the actual work.
#'  
#' @param sf_id integer: id of an entry in the f_substances table
#' @return list(err, exists, complete, sf_id): list containing one integer
#'          - indicating if no error (==0) or an error (!=0) occured -, three 
#'          booleans - indicating if the endtry already exists and if it is
#'          complete - and the sf_id which was parsed at the beginning.
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
completeFSubstance <- function(sf_id) {
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = completeFSubstance.RODBC(channel, sf_id)
  close(channel)
  
  return(return_val)
}
