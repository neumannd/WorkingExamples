#' Test an EMEP data file returned by the read.emepFile for duplicate
#' variables and parse back the indices of duplicate variables. The short
#' variable names, the matrices and the method_refs are tested for 
#' duplicates.
#' 
#' WE HAVE TWO SIMILAR FUNCTIONS 'findDuplicatesNamesOnly.emepdata' AND 
#' 'findDuplicates.emepdata'. WHILE THE FIRST ONE ONLY COMPARES THE short 
#' variable name, THE SECOND ONE COMPARES short variables name, matrix and 
#' method_ref. 
#' 
#' The short variables names are emepdata$measurements$titleVarsShort
#' The matrices are emepdata$measurements$matrices
#' The method_refs are emepdata$measurements$method_refs
#' 
#' @param emepdata ; an EMEP data file given out by read.emepFile
#' @return integer_array ; integer array ; an array of integers giving the  
#'    positions of duplicate variables in the input file (titleVarsShort,
#'    matrix and method_ref are tested)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note If no duplicates are present, an empty list is returned. 
#' @format R Code
#' @export 
findDuplicates.emepdata <- function(emepdata) {
  return((1:emepdata$nVars)[duplicated(
    paste(
      emepdata$measurements$titleVarsShort,
      emepdata$measurements$matrices,
      emepdata$measurements$instrument,
      emepdata$measurements$method_refs,
      sep="_"
    )
  )]
  )
}
