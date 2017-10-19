#' Convert a time
#' 
#' The array times contains dates of measurements in
#' days (real variable; + hours divided by 24) with 
#' respect to a reference date refDate. refDate has to
#' be given in Julian format (YYYYDDD).
#' 
#' @param times ; 
#' @param refDate ; 
#' @return newTimes ; 
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export 
reworkTiming <- function(times, refDate) {
  workingTimes = times
  nDates = length(workingTimes)
  newTimes = rep(0, nDates)
  
  YEAR <- floor(refDate/1000)
  
  actRefDate = refDate
  maxDoy = getMaxDoy(YEAR)
  
  for (i1 in 1:nDates) {
    tmpDate = actRefDate + workingTimes[i1]
    
    while (tmpDate <= YEAR*10^3){
      oldYEAR = YEAR
      YEAR = YEAR - 1
      maxDoy = getMaxDoy(YEAR)
      tmpDate = maxDoy - (oldYEAR*10^3 - tmpDate)
      actRefDate = maxDoy + (actRefDate - oldYEAR*10^3)
    }
    
    while (tmpDate > maxDoy) {
      oldYEAR = YEAR
      YEAR = YEAR + 1
      tmpDate = YEAR*10^3 + (tmpDate-maxDoy)
      actRefDate = YEAR*10^3 - (maxDoy - actRefDate)
      maxDoy = getMaxDoy(YEAR)
    }
    
    newTimes[i1] = tmpDate
  }
  
  return(newTimes)
}
