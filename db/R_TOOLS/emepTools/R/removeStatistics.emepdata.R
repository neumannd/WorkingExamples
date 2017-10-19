#' Remove all statistic variables from an EMEP data variable/list (emepdata),
#' which are unequal 'arithmetic mean'. 
#' 
#' Remove all statistic variables from an EMEP data variable/list (emepdata),
#' which are unequal 'arithmetic mean'. 
#' 
#' Remove all statistic variables from an EMEP data variable/list (emepdata),
#' which are unequal 'arithmetic mean'. 
#' 
#' The function removeEntries.emepdata removes the entries.
#' 
#' @param emepdata emepdata: an EMEP data file given out by read.emepFile
#' @return \item{changes}{logical: FALSE if new_data equals
#'          emepdata and TRUE otherwise (= if variables were dropped)}
#'  \item{removeList}{integer array: the same integer array as returned
#'          by findDuplicates.emepdata(emepdata)}
#'  \item{new_data}{list(): list of the same format as that 
#'          given back by the read.emepFile but without duplicate 
#'          variables (titleVarsShort)}
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note no note
#' @format R Code
#' @export 
removeStatistics.emepdata <- function(emepdata) {
  
  removeList = c()
  
  for (i1 in 1:emepdata$nVars) {
    if('Statistics'%in%names(emepdata$measurements$addVarInfo[[i1]])) {
      if(emepdata$measurements$addVarInfo[[i1]]$Statistics != 'arithmetic mean') removeList = c(removeList, i1)
    }
  }
  
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
