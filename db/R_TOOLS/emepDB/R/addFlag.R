#' Adds a new numflag to the EMEP database
#'
#' Adds a new numflag to the EMEP database
#' 
#' Structure of flag: list(numflag, status, description, flaggroup, group_description) 
#'
#' @param flag list(): list with information on the flag to insert; flaggroup is optional if floor(numflag/100)==flaggroup; group_description is optional if no new flaggroup should be created
#' @param create_group logical: create a new flaggroup if necessary (default = FALSE)
#' @param no_insert_on_warning logical: TRUE = do nothing if a warning was thrown (default = TRUE)
#' @return list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export 
addFlag = function(flag, create_group = FALSE, no_insert_on_warning = TRUE) {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = addFlag.RODBC(channel, flag, create_group, no_insert_on_warning)
  close(channel)
  
  return(return_val)
  
}
