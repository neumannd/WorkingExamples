#' Remove variables from an EMEP data variable/list (emepdata) as
#' parsed by removeList.
#' 
#' Remove variables from an EMEP data variable/list (emepdata) as
#' parsed by removeList.
#' 
#' Following parts of emepdata are changed if duplicates are present:
#'  drop elements:
#'    measurements$titleVarsLong
#'    measurements$titleVarsShort
#'    measurements$units
#'    measurements$matrices
#'    measurements$method_refs
#'    measurements$variables
#'      note: variables is a 2-dim array; the 2nd dimension has to be changed
#'    flags$titleFlagsLong
#'    flags$titleFlagsShort
#'    flags$numflags
#'      note: variables is a 2-dim array; the 2nd dimension has to be changed
#'  alter integer:
#'    nVars
#' 
#' @param emepdata emepdata: an EMEP data file given out by read.emepFile
#' @param removeList integer array: (optional) an integer array containing
#'    indices of variables which shoul be removed from emepdata;
#' @return new_data a list() of the same format as that 
#'          given back by the read.emepFile but without duplicate 
#'          variables (titleVarsShort)
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note If no duplicates are present, new_data equals emepdata and changes
#'    is FALSE
#' @format R Code
#' @export 
removeEntries.emepdata <- function(emepdata, removeList=c()) {
  
  # Copy emepdata into new variable
  new_data = emepdata
  
  # If removeList has a length of 0 we do nothing. This is the case when 
  # findDuplicates.emepdata does not find any duplicates in emepdata.
  if (length(removeList) == 0) {
    # Copy emepdata into new variable
    new_data = emepdata
  } else {
    # Drop duplicate variables
    new_data$measurements$titleVarsLong = emepdata$measurements$titleVarsLong[-removeList]
    new_data$measurements$titleVarsShort = emepdata$measurements$titleVarsShort[-removeList]
    new_data$measurements$units = emepdata$measurements$units[-removeList]
    new_data$measurements$matrices = emepdata$measurements$matrices[-removeList]
    new_data$measurements$method_refs = emepdata$measurements$method_refs[-removeList]
    new_data$measurements$addVarInfo = emepdata$measurements$addVarInfo[-removeList]
    new_data$measurements$variables = emepdata$measurements$variables[,-removeList]
    new_data$flags$titleFlagsLong = emepdata$flags$titleFlagsLong[-removeList]
    new_data$flags$titleFlagsShort = emepdata$flags$titleFlagsShort[-removeList]
    new_data$flags$numflags = emepdata$flags$numflags[,-removeList, ] 
    
    if(emepdata$nVars - length(removeList) == 1) {
      dim(new_data$measurements$variables) = c(emepdata$nRowData, 1)
      dim(new_data$flags$numflags) = c(emepdata$nRowData, 3)
    }
    
    # Set new number of variables
    new_data$nVars = length(new_data$measurements$titleVarsLong)
  }
  
  # Return the modified data (new_data)
  return(new_data)
}
