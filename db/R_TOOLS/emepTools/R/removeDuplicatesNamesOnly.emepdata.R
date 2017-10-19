#' PLEASE USE removeDuplicates.emedata().
#' 
#' Remove duplicate variables from an EMEP data variable/list (emepdata) as
#' returned by read.emepFile and getEmptyEmepData.
#' 
#' The array indices of duplicate variables are identified by the function
#' findDuplicatesNamesOnly.emepdata(emepdata).
#' 
#' The function removeEntries.emepdata removes the entries.
#' 
#' @param emepdata emepdata: an EMEP data file given out by read.emepFile
#' @param removeList emepdata: (optional) an integer array containing
#'    indices of variables which shoul be removed from emepdata; if not 
#'    parsed, removedList is filled by the call of 
#'    findDuplicates.emepdata(emepdata)
#' @return \item{changes}{logical: FALSE if new_data equals
#'          emepdata and TRUE otherwise (= if variables were dropped)}
#'  \item{removeList}{integer array: the same integer array as returned
#'          by findDuplicates.emepdata(emepdata)}
#'  \item{new_data}{list(): list of the same format as that 
#'          given back by the read.emepFile but without duplicate 
#'          variables (titleVarsShort)}
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note If no duplicates are present, new_data equals emepdata and changes
#'    is FALSE
#' @format R Code
#' @export 
removeDuplicatesNamesOnly.emepdata <- function(emepdata, removeList=findDuplicatesNamesOnly.emepdata(emepdata)) {
  .Deprecated(removeDuplicates.emepdata, package = NULL, msg = "The function 'removeDuplicates.emepdata' should be used because it considers substance_short, matrix and method_ref for the duplicated identification.")
  
  # If removeList has a length of 0 we do nothing. This is the case when 
  # findDuplicates.emepdata does not find any duplicates in emepdata.
  if (length(removeList) == 0) {
    changes = FALSE
    # Copy emepdata into new variable
    new_data = emepdata
  } else {
    changes = TRUE
    # Drop duplicate variables
    new_data = removeEntries.emepdata(emepdata, removeList)
  }
  
  # Return the modified data (new_data), the information whether the data was
  # actually modified (changes) and the old indices which were dropped 
  # (removeList).
  return(list(
    'changes'=changes,
    'removeList'=removeList,
    'new_data'=new_data
  ))
}
