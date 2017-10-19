#' private: set a row in the f_substance table as 'complete'
#' 
#' Sets the 'complete' boolean of one entry in table 'f_substances'
#' to TRUE. Returns whether it was successful or not. Does not test
#' whether an entry exists, in advance. The database
#' access is provided by 'channel'.
#' 
#' @param channel RODBC: handle to existing database connection
#' @param sf_id integer: id of an entry in the f_substances table
#' @return list(err, exists, complete, sf_id): list containing one integer
#'          - indicating if no error (==0) or an error (!=0) occured -, three 
#'          booleans - indicating if the endtry already exists and if it is
#'          complete - and the sf_id which was parsed at the beginning.
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
completeFSubstance.RODBC <- function(channel, sf_id) {
  queryString = paste("UPDATE f_substances SET complete=TRUE WHERE ",
                      "sf_id=", sf_id, 
                      ";", sep="")
  queryOut = sqlQuery(channel, query=queryString)
  if (length(grep("ERROR", queryOut)) != 0) {
    err=1
    exists=FALSE
    complete=FALSE
  } else {
    err=0
    exists=TRUE
    complete=TRUE
  }
  
  return(list("err"=err, "exists"=exists, "complete"=complete, "sf_id"=sf_id))
}
