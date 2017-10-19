#' private: adds and new row into the f_substance table
#' 
#' Inserts a new line into the f_substances table of the database,
#' to which an open connection via 'channel' exists.
#' 
#' @param channel RODBC: open RODBC database connection
#' @param sgl_id integer: sgl_id pointing to a row in the sgl_files tables
#' @param substance_short character: short substance name
#' @param matrix character: matrix of the measurement (air, aerosol, precip)
#' @param method_ref character: method_ref of the measurement
#' @return list(err, exists, complete, sf_id) list(integer, logical, logical, integer): exists or not
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
addFSubstance.RODBC <- function(channel, sgl_id, substance_short, matrix, method_ref) {
  queryString = paste("INSERT INTO f_substances (sgl_id, substance_short, matrix, method_ref)",
                      " VALUES(", sgl_id, ", ",
                      substance_short, ", ",
                      matrix, ", ",
                      method_ref,
                      ");", sep="")
  queryOut = sqlQuery(channel, query=queryString)
  
  if (length(grep("ERROR", queryOut)) == 0) {
    queryResult = existsFSubstance.RODBC(channel, sgl_id, substance_short, matrix, method_ref)
    
    if (queryResult$err != 0) {
      err = queryResult$err
      sf_id = -1
      exists=FALSE
      complete=FALSE
    } else {
      if (queryResult$exists) {
        err = 0
        sf_id = queryResult$sf_id
        exists=TRUE
        complete=FALSE
      } else {
        err = 2
        sf_id = -1
        exists=FALSE
        complete=FALSE
      }
    }
  } else {
    err = 1
    sf_id = -1
    exists=FALSE
    complete=FALSE
  }
  
  return(list("err"=err, "exists"=exists, "complete"=complete, "sf_id"=sf_id))
}
