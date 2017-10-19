#' Identify variables in EMEP data variable/list (emepdata) with problematic attributes
#' 
#' Identify variables in EMEP data variable/list (emepdata) with problematic attributes
#' 
#' Identify variables in EMEP data variable/list (emepdata) with problematic attributes
#' 
#' These are:
#'  - Fraction
#'  - Statistics && Statistics != 'arithmetic mean'
#'  - FURTHER???
#'  
#' These can be resolved:
#'  - Statistics: removeStatistics.emepdata(emepdata)
#' 
#' @param emepdata RODBC: an EMEP data file given out by read.emepFile
#' @return \item{problemIndices}{integer array: indices of problematic variables}
#'  \item{allVars}{list(): a list containing one list per variable (not only of problematic ones); 
#'  the nested lists are numbered according to the variables in emepdata (not by variable name 
#'  because these might be duplicates). Each nested list has a 'name' and optionally a 'Fraction', 
#'  'Statistics' or further elements. Having other elements than 'name' does not indicate that
#'  the variable is problematic. Only the 'problemIndices' states, which variables are problematic.}
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note nothing
#' @export
#' @format R Code
findProblematicAttributes.emepdata = function(emepdata) {
  
  problemIndices = c()
  allVars = array(list(), dim = emepdata$nVars)
  
  for (i1 in 1:emepdata$nVars) {
    problem = FALSE
    varName = emepdata$measurements$titleVarsShort[i1]
    allVars[[i1]] = list('name' = varName)
    
    ## problem: statistics
    if('Statistics'%in%names(emepdata$measurements$addVarInfo[[i1]])) {
      allVars[[i1]]$Statistics = emepdata$measurements$addVarInfo[[i1]]$Statistics
      if(emepdata$measurements$addVarInfo[[i1]]$Statistics != 'arithmetic mean') {
        problem = TRUE
      }
    }
    
    ## problem: fraction
    if('Fraction'%in%names(emepdata$measurements$addVarInfo[[i1]])) {
      problem = TRUE
      allVars[[i1]]$Fraction = emepdata$measurements$addVarInfo[[i1]]$Fraction
    }
    
    if (problem) problemIndices = c(problemIndices, i1)
  }
  
  return(list('problemIndices' = problemIndices, 'allVars' = allVars))
  
}
