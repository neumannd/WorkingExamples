#' Seconds since 1900-01-01 00:00:00 UTC
#' 
#' Calculate seconds since 1900-01-01 00:00:00 UTC by the use of as.POSIXct
#' 
#' 
#' ~~ Procedure ~~
#' We will use the formular:
#' 
#' as.numeric(as.POSIXct(JULIAN_DATE, tz = 'UTC')) - as.numeric(as.POSIXct("1900-01-01 00:00:00 UTC", tz = 'UTC'))
#' 
#' However, the JULIAN_DATE needs to be build first.
#' 
#' 
#' ~~ Test ~~
#' from http://www.esqsoft.com/javascript_examples/date-to-epoch.htm
#'
#' Seconds from 1900-01-01 00:00:00 UTC to 1970-01-01 01:00:00 UTC:: -2208992400
#' Seconds from 1970-01-01 01:00:00 UTC to 2012-01-01 00:00:00 UTC:: 1325372400
#' 
#' Seconds calculated by this programm from 1900-01-01 00:00:00 UTC to 2012-01-01 00:00:00 UTC:: 3534364800
#' 
#' @author Daniel Neumann, daniel.neumann@posteo.de
#' @date 2016-10-09
#' @version 1.0
#' @param julianDateInt integer: julian date in the CMAQ format (YYYYDDD)
#' @param hour integer: hour / time of the day (between 0.0 and 23.9999)
#' @return seconds: seconds since 1900-01-01 00:00:00 UTC
getSecondsSince1990fromJulian = function(julianDateInt = 2012001, hour = 0) {
  
  doyInt = julianDateInt%%1000
  julianDateStr = formatC(julianDateInt, format = 'd', width = 7)
  yearStr = substr(julianDateStr, 1, 4)
  
  refDate = "1900-01-01 00:00:00 UTC"
  
  # we calculate -1 because this day is not elapsed yet
  iDateLong = as.POSIXct((doyInt-1) * 86400 + hour * 3600, origin = paste(yearStr, "01-01 00:00:00 UTC", sep = '-'), tz = 'UTC')
  intSecSince = as.numeric(as.POSIXct(iDateLong, tz = 'UTC')) - as.numeric(as.POSIXct(refDate, tz = 'UTC'))
  
  return(intSecSince)

}
