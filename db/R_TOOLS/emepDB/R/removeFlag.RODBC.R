#' Removes a numflag from the EMEP database
#' 
#' @param channel RODBC: open RODBC database connection
#' @param numflag character: numflag of the flag to remove; is unambiguous;
#' @return list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export
removeFlag.RODBC = function(channel, numflag) {
  
  err_code = 0
  
  # numflag tests ----
  if ( is.null(numflag) ) stop("removeFlag: numflag is empty")
  if ( !(class(numflag)%in%c('numeric', 'integer')) ) stop("removeFlag: Type of numflag needs to be 'integer' or 'numeric'.")
  if ( numflag > 32767 ) stop("removeFlag: Value of numflag is too high (max 32767).")
  if ( numflag >= 1000 ) warning("removeFlag: Value of flag$numflag is above 999.")
  int_numflag = as.integer(numflag)
  
  test_numflag = sqlQuery(channel, paste("SELECT * FROM flags WHERE numflag = ", int_numflag, ";", sep = ""))
  if ( dim(test_numflag)[1] == 0 ) {
    returnDelete = paste('removeFlag: numflag ', int_numflag, ' does not exist.', sep = '')
    warning(returnDelete)
    err_code = 1
  }
  
  # deleting data ----
  if (err_code == 0) {
    # create delete string
    deleteString = paste("DELETE FROM flags WHERE numflag = ", int_numflag, ";", sep = '')
    
    # print it
    print(deleteString)
    
    # perform deletion
    returnDelete <- sqlQuery(channel, query=deleteString)
    
    # give user feedback
    if (length(returnDelete) == 0) {
      print('Deletion was performed without errors.')
      err_code = 0
    } else {
      warning('removeFlag: an error was thrown during deletion from the database')
      print(returnDelete)
      err_code = 1
    }
  } else print(returnDelete)
  
  return(list('err_code' = err_code, 'err_string' = returnDelete))
}
