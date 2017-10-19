#' Test an EMEP data file returned by the read.emepFile for duplicate
#' variables and parse back the indices of duplicate variables. The short
#' variable names are tested for duplicates.
#' 
#' WE HAVE TWO SIMILAR FUNCTIONS 'findDuplicatesNamesOnly.emepdata' AND 
#' 'findDuplicates.emepdata'. WHILE THE FIRST ONE ONLY COMPARES THE short 
#' variable name, THE SECOND ONE COMPARES short variables name, matrix and 
#' method_ref. 
#' 
#' The short variables names are emepdata$measurements$titleVarsShort
#' 
#' @param emepdata ; an EMEP data file given out by read.emepFile
#' @return integer_array ; integer array ; an array of integers giving the  
#'    positions of duplicate variables in the input file (titleVarsShort is 
#'    tested)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note If no duplicates are present, an empty list is returned. 
#' @format R Code
#' @export 
findDuplicatesNamesOnly.emepdata <- function(emepdata) {
  # What do we do here?
  #  - emepdata$measurements$titleVarsShort
  #    + get a character array containing the short variable names
  #  - duplicated({SHORT_VAR_NAMES})
  #    + get a boolean array of the same length as {SHORT_VAR_NAMES}
  #    + The entry in the boolean array is FALSE if the corresponding
  #       value in {SHORT_VAR_NAMES} has no duplicate or if is the 
  #       first duplicate value seen from the left. Otherwise the entry
  #       is TRUE.
  #    + see documentation of duplicated() for details
  #  - (1:emepdata$nVars)[{TAKE_ONLY}]
  #    + list from 1 to emepdata$nVars but take only those values where
  #       {TAKE_ONLY} is TRUE (if this is a boolean array) or those values
  #       which indices are given by {TAKE_ONLY} (if this is a integer array).
  return((1:emepdata$nVars)[duplicated(emepdata$measurements$titleVarsShort)])
}
