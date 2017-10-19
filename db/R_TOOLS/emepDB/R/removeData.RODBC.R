#' private: remove rows from data table
#'
#' Removes all rows from the data table which have a given sf_id. Prior to 
#' sending the DELETE query, the presence of data row with this sf_id is
#' tested.
#'
#' @param channel RODBC: open ODBC data basebase connection
#' @param sf_id integer: id of an entry in the f_substances table
#' @return list(err_code, n_rows) list(integer, integer): !=0 if an error occured; number of removed rows
#' @author Daniel Neumann, daniel.neumann@___.de
#' @format R Code
removeData.RODBC = function(channel, sf_id) {
  
  err_code = 0
  n_rows = 0
  
  existsString = paste('SELECT * FROM data WHERE sf_id = ', sf_id, ';', sep = '')
  queryExists = sqlQuery(channel, query = existsString)
  n_rows = dim(queryExists)[1]
  
  if (is.null(n_rows)) {
    n_rows = 0
    err_code = 1
  }
  
  if (n_rows > 0 && err_code == 0) {
    removeString = paste('DELETE FROM data WHERE sf_id = ', sf_id, ';', sep = '')
    queryRemove = sqlQuery(channel, query = removeString)
    
    if (length(queryRemove) != 0) err_code = 2
  }
  
  return(list('err_code' = err_code, 'n_rows' = n_rows))
}
