#' private: checks whether a certain variable already exists in the f_substance table
#' 
#' Tests whether a substance measured in a given matrix and method_ref 
#' (pointing to sgl_id) does alreay exist in the database. A connection to 
#' the database defined by the variable DBaccess is established.
#' The function existsFSubstance.RODBC does the actual work.
#' 
#' @param sgl_id integer: sgl_id pointing to a row in the sgl_files tables
#' @param substance_short character: short substance name
#' @param matrix character: matrix of the measurement (air, aerosol, precip)
#' @param method_ref character: method_ref of the measurement
#' @return list(err, exists, complete, sf_id) list(integer, logical, logical, integer): exists or not
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
existsFSubstance <- function(sgl_id, substance_short, matrix, method_ref) {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = existsFSubstance.RODBC(channel, sgl_id, substance_short, matrix, method_ref)
  close(channel)
  
  return(return_val)
}
