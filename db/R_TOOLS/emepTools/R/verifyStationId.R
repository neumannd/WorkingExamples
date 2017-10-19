#' Tests whether a station_id has the correct format
#' 
#' @param station_id character: id of an measurement station
#' @return list(station_id, err_code, warn_code) list(character, integer): err_code (0 = success; 1 err), warn_code (0 = no warn; 1 = warning);
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export 
verifyStationId = function(station_id) {
  
  err_code = 0
  warn_code = 0
  
  # (a): station_id is not a character variable
  if( class(station_id) != 'character' ) {
    warn_code = 1
    warning('verifyStationId: station_id was an integer and has been converted to character')
    # (a.1): station_id (is assumed to be a number) has more than 7 integer digits => error
    if (station_id >= 10^7) {
      err_code = 1
      stop('verifyStationId: length of station_id above 7 digits')
    }
    # (a.2): station_id (is assumed to be a number) has 7 or less digits and is converted into a character string
    out_station_id = formatC(station_id, format = 'd', width = 7)
    
  # (b): station_id is a character variable
  } else {
    strlen = nchar(station_id)
    # (b.1): station_id consists of more than 7 characters
    if (strlen > 7) {
      err_code = 1
      out_station_id = substr(station_id, strlen-6, strlen)
      stop('verifyStationId: length of station_id above 7 characters')
    # (b.2): station_id consists of less than 7 characters
    } else if (strlen < 7) {
      warn_code = 1
      out_station_id = substr(paste("      ", station_id, sep = ""), strlen, strlen+6)
      warning('verifyStationId: station_id consists of less than 7 character; trailing spaces were added')
    # (b.3): station_id has a length of 7 characters
    } else {
      out_station_id = station_id
    }
  }
  
  return(list('station_id' = out_station_id, 
              'err_code' = err_code,
              'warn_code' = warn_code))
}
