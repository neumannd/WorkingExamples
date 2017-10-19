#' Adds a new numflag to the EMEP database
#'
#' Adds a new numflag to the EMEP database
#' 
#' Structure of flag: list(numflag, status, description, flaggroup, group_description) 
#'
#' @param channel RODBC: open RODBC database connection (\emph{RODBC})
#' @param flag list(numflag, status, description, flaggroup, group_description): list with information on the flag to insert; flaggroup is optional if floor(numflag/100)==flaggroup; group_description is optional if no new flaggroup should be created
#' @param create_group logical: create a new flaggroup if necessary (default = FALSE)
#' @param no_insert_on_warning logical: TRUE = do nothing if a warning was thrown (default = TRUE)
#' @return list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export 
addFlag.RODBC = function(channel, flag, create_group = FALSE, no_insert_on_warning = TRUE) {
  
  if (class(flag) != 'list') stop("'flag' has wrong format.")
  
  err_code = 0
  warn_code = 0
  
  do_insert_group = FALSE
  do_insert_flag = TRUE
  
  returnNumFlag = ''
  returnFlagGroup = ''
  
  
  # numflag tests ----
  if ( is.null(flag$numflag) ) stop("addFlag: flag$numflag is empty")
  if ( !(class(flag$numflag)%in%c('numeric', 'integer')) ) stop("addFlag: Type of flag$numflag needs to be 'integer' or 'numeric'.")
  if ( flag$numflag > 32767 ) stop("addFlag: Value of flag$numflag is too high (max 32767).")
  if ( flag$numflag >= 1000 ) { warning("addFlag: Value of flag$numflag is above 999."); warn_code = 1 }
  int_numflag = as.integer(flag$numflag)
  test_numflag = sqlQuery(channel, paste("SELECT * FROM flags WHERE numflag = ", int_numflag, ";", sep = ""))
  if ( dim(test_numflag)[1] > 0 ) {
    returnNumFlag = paste('addFlag: numflag ', int_numflag, ' already exists.', sep = '')
    stop(returnNumFlag)
    err_code = 1; warn_code = 1; do_insert_flag = FALSE
  }
  
  
  # flaggroup tests ----
  if ( is.null(flag$flaggroup) ) {
    int_flaggroup = floor(flag$numflag/100)
    print(paste("addFlag: flag$flaggroup not defined. Setting flaggroup to ", int_flaggroup, '.', sep = ''))
    if (int_numflag > 999 || (int_numflag < 100 && int_numflag != 0)) {
      warning("addFlag: Derived value for flaggroup might be incorrect because numflag was outside of the standard range [000, 100 ... 999].")
      warn_code = 1
    }
  } else {
    if ( !(class(flag$flaggroup)%in%c('numeric', 'integer')) ) stop("addFlag: Type of flag$flaggroup needs to be 'integer' or 'numeric'.")
    int_flaggroup = as.integer(flag$flaggroup)
  }
  
  test_flaggroup = sqlQuery(channel, paste("SELECT * FROM flaggroups WHERE flaggroup = ", int_flaggroup, ";", sep = ""))
  if (dim(test_flaggroup)[1] == 0) {
    if ( create_group && (!is.null(flag$group_description)) ) {
      do_insert_group = TRUE
      str_group_description = paste("'", flag$group_description, "'", sep = '')
    } else {
      do_insert_group = FALSE
      do_insert_flag = FALSE
      if ( !create_group ) {
        tmpString = "addFlag: No insertion performed. A new flaggroup needs to be created but 'create_group' is set to FALSE."
        warning(tmpString)
        err_code = 1; warn_code = 1
        if( nchar(returnFlagGroup) == 0 ) returnFlagGroup = tmpString else returnFlagGroup = paste(returnFlagGroup, ';; ', tmpString, sep = '')
      }
      if ( is.null(flag$group_description) ) {
        tmpString = "addFlag: No insertion performed. A new flaggroup needs to be created but 'flag$group_description' is empty."
        warning(tmpString)
        err_code = 1; warn_code = 1
        if( nchar(returnFlagGroup) == 0 ) returnFlagGroup = tmpString else returnFlagGroup = paste(returnFlagGroup, ';; ', tmpString, sep = '')
      }
    }
  }
  
  
  
  # status tests ----
  if ( is.null(flag$status) ) stop("addFlag: flag$status is empty")
  if ( class(flag$status) != 'character' ) {
    if ( class(flag$status)%in%c('numeric', 'integer') ) {
      str_status = formatC(as.integer(flag$status), format = 'd')
    } else {
      stop("addFlag: Type of flag$status has to be 'character' (ideal choice), 'integer' or 'numeric'.")
    }
  } else {
    str_status = flag$status
  }
  
  if ( nchar(str_status) > 1 ) stop("addFlag: flag$status has to have one character/digits.")
  str_status = paste("'", str_status, "'", sep = '')
  
  
  
  # description tests ----
  if ( is.null(flag$description) ) stop("addFlag: flag$description is empty")
  if ( class(flag$description) != 'character' ) stop("addFlag: Type of flag$description needs to be 'character'.")
  str_description = paste("'", flag$description, "'", sep = '')
  
  
  
  # insert flaggroup data ----
  if (no_insert_on_warning && warn_code != 0 && err_code == 0) {
    returnNumFlag = "No insertion was performed because 'no_insert_on_warning' is set and warning(s) occured (but not errors)."
    returnFlagGroup = returnNumFlag
    print(returnNumFlag)
    err_code = 1
  } else {
    if (do_insert_flag && do_insert_group ) {
      # create insert string for flaggroup
      insertStringFlagGroup = paste("INSERT INTO flaggroups",
                                "(flaggroup, description)",
                                " VALUES(",
                                int_flaggroup, ", ", str_group_description, ");", 
                                sep="")
      
      # print it
      print(insertStringFlagGroup)
      
      # perform insertion
      returnFlagGroup = sqlQuery(channel, query=insertStringFlagGroup)
      
      # give user feedback
      if (length(returnFlagGroup) == 0) {
        print('Insertion of flaggroup was performed without errors.')
      } else {
        warning('addFlag: an error was thrown during insertion of new flaggroup into the database')
        print(returnFlagGroup)
        err_code = 1
        do_insert_flag = FALSE
      }
    }
    
    if (do_insert_flag) {
      # create insert string for numflag
      insertStringNumFlag = paste("INSERT INTO flags",
                                  "(numflag, status, description, flaggroup)",
                                  " VALUES(",
                                  int_numflag, ", ", str_status, ", ", str_description, ", ",
                                  int_flaggroup, ");", 
                                  sep="")
      # print it
      print(insertStringNumFlag)
      
      # perform insertion
      returnNumFlag <- sqlQuery(channel, query=insertStringNumFlag)
      
      # give user feedback
      if (length(returnNumFlag) == 0) {
        print('Insertion of numflag was performed without errors.')
      } else {
        print(returnNumFlag)
        stop('add_numflag: an error was thrown during insertion of new numflag into the database')
        err_code = 1
      }
    } else {
      print(returnFlagGroup)
    }
  }
  
  
  return(list('err_code' = err_code, 'warn_code' = warn_code, 'err_string_numflag' = returnNumFlag, 'err_string_flaggroup' = returnFlagGroup))
}
