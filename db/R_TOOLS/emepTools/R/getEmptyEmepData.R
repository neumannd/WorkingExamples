#' Creates empty list according to read.emepFile .
#' 
#' @return emep_file ; list ; Empty list which has (or should have) the same
#'    structure as the returned list from function read.emepFile.
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note Please update if read.emepFile is updated. 
#' @format R Code
#' @export 
getEmptyEmepData <- function() {
  return(list("filename"="",
              "timing"=list("titleTimes" = c("start_time_yyyyddd", "start_time_hh", "end_time_yyyyddd", "end_time_hh"),
                            "times" = array(0.0, dim = c(1,4)),
                            "resolution" = "",
                            "timeOfDay" = list("hour" = 0, "minute" = 0)),
              "measurements"=list("titleVarsLong" = "", 
                                  "titleVarsShort" = "", 
                                  "units" = "", 
                                  "matrices" = "",
                                  "method_refs" = "",
                                  "addVarInfo" = c(""), 
                                  "variables" = array(0.0, dim = c(1,1))),
              "flags"=list("titleFlagsLong" = "", 
                           "titleFlagsShort" = "",
                           "numflags" = array(0.0, dim = c(1,1,3))),
              "addDataInfo" = list(), 
              "specialInfo" = "",
              "dataOrigin" = c(""),
              "whereToFind" = c(""),
              "nVars" = 1, 
              "nRowData" = 1)
  )
}
