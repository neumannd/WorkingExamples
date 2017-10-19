#' private: Insert data into the EMEP database (please use addFile)
#'
#' Please use addFile() to add data to the database if you 
#' are not really sure what you are doing. Adds data (emepdata) 
#' into the database defined by the DBaccess variables. A 
#' RODBC connection (channel) is opend for this purpose.
#' 
#' @param emepdata list: EMEP data to write into the database
#' @param file_id_IN integer: id of the entry in the files table corresponding to the currently being imported data set
#' @param sgl_id_IN integer: id of the entry in the sgl_files table corresponding to the currently being imported data set
#' @return list(): information whether the process was successful or not
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
addData <- function(emepdata, file_id_IN, sgl_id_IN) {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = addData.RODBC(channel, emepdata, file_id_IN, sgl_id_IN)
  close(channel)
  
  return(return_val)
}
