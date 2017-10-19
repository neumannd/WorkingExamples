#' private: checks whether a certain variable already exists in the f_substance table
#' 
#' Tests whether a substance measured in a given matrix and method_ref 
#' (pointing to sgl_id) does alreay exist in the database. The database
#' access is provided by 'channel'.
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
existsFSubstance.RODBC <- function(channel, sgl_id, substance_short, matrix, method_ref) {
  queryString = paste("SELECT sf_id, complete FROM f_substances WHERE ", 
                      "sgl_id=", sgl_id, 
                      " AND substance_short=", substance_short,
                      " AND matrix=", matrix,
                      " AND method_ref=", method_ref,
                      ";", sep="")
  
  queryOut = sqlQuery(channel, query=queryString)
  
  if (length(grep("ERROR", queryOut)) == 0) {
    err = 0 
    if (dim(queryOut)[1] > 0) {
      exists = TRUE
      sf_id = queryOut[1, "sf_id"]
      if (queryOut[1, "complete"]) complete = TRUE else complete = FALSE
    } else {
      exists = FALSE
      complete = FALSE
      sf_id = -1
    }
  } else {
    err = 1
    exists = FALSE
    complete = FALSE
    sf_id = -1
  }
  
  return(list("err"=err, "exists"=exists, "complete"=complete, "sf_id"=sf_id))
}
