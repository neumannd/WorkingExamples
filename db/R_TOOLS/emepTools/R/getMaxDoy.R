#' Calculate last day of a year as Julian date (366 or 365)
#' 
#' Calculate the last day of the year "year" in the date format YYYYDDD. Year 
#' is an integer of the format YYYY. Thus, the year 1993 is parsed as 
#' year=1993 and NOT as year=93.
#' 
#' It is tested whether "year" is a leap year or not. If it is leap year
#' doy=YYYY366 and if not doy=YYYY365. doy always has 7 digits.
#' 
#' Alternative and shorter form that can be used directly in the code:
#' 
#' julian(as.Date(paste(year,"-12-31",sep="")), origin=as.Date(paste(year,"-01-01",sep="")))+1
#' 
#' @param year (integer): The year (YYYY format) for which the last day of the year should be
#'    calculated.
#' @return doy (integer): The last day of the year "year" in the YYYYDDD format
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note There is an alternative and shorter form. 
#' @format R Code
#' @export 
#' @examples
#'   # choose a non-leap year (e.g. 1993)
#'   myYear = 1993
#'   myLastDoy = getMaxDoy(myYear)
#'   # 1993 is no leap year. Hence the output should be 1993365
#'   print(myLastDoy)
#'   
#'   
#'   # choose a leap year (e.g. 2004)
#'   myYear = 2004
#'   myLastDoy = getMaxDoy(myYear)
#'   # 2004 is a leap year. Hence the output should be 2004366
#'   print(myLastDoy)
#'   
#'   # an alternative method to calculate the last doy is:
#'   myYear = 2001
#'   (julian(as.Date(paste(myYear,"-12-31",sep="")), origin=as.Date(paste(myYear,"-01-01",sep="")))+1)[1]
#'   myYear = 2004
#'   (julian(as.Date(paste(myYear,"-12-31",sep="")), origin=as.Date(paste(myYear,"-01-01",sep="")))+1)[1]
#'   
getMaxDoy <- function(year) {
  # Alternative and shorter form:
  # julian(as.Date(paste(year,"-12-31",sep="")), origin=as.Date(paste(year,"-01-01",sep="")))+1
  
  # If year is no integral multiple of 4 we have definitely no leap year
  # and doy is set to YYYY365.
  if(year %% 4 != 0) {
    doy = year*10^3 + 365
  } else {
    # Every century a leap year is skipped (1700, 1800, 1900 etc.) but not
    # it can be divided by 400 (1600, 2000 etc.). In the latter case the 
    # year is a leap year.
    if (year %% 100 == 0 && year %% 400 != 0) {
      doy = year*10^3 + 365
    } else {
      doy = year*10^3 + 366
    }
  }
  return(as.integer(doy))
}
