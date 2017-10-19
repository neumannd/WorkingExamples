#' converts an emepdata variable into a variables usable in the ctmeval package
#' 
#' converts a list in emepdata format into a list of the format
#' produced by ctmeval (observationts format). However, the returned
#' list contains three additional elements that are
#'      $station$altitude
#'      $timeser$hour
#'      $method_ref
#' 
#' @param emepdata (emepdata): list in the emepdata format
#' @param vlevels (integer array): array containing valid flags (all values with flags that
#'                    are not in this array are set to NA)
#' @param calc_mean (logical): calculate mean values if TRUE, standard is TRUE
#' @param mean_type (character): calculate which type of mean? standard is daily
#' @param dsum (logical): calculate sum instead of mean if TRUE, standard is FALSE
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @return timeseries of observations in observationsts format (in accordance
#'                     with the ctmeval package v0.9.5.1)
#' @format R Code
#' @export 
#' @examples
#' # read emep data file
#' myEmepdata = getEmptyEmepData() # TODO!!!
#' # convert into ctmeval format
#' data_ctmeval = convert2ctmeval.emepdata(myEmepdata)
#'
convert2ctmeval.emepdata <- function(emepdata, vlevels = 0, calc_mean = TRUE, mean_type = 'daily', dsum = FALSE) {
  
  
  #' Find out if sum instead of mean should be applied. Further below, 'fun_apply'
  #' is the 'FUN' input argument of an 'apply' call which calculates the mean/sum.
  if (dsum) fun_apply = 'sum' else fun_apply = 'mean'
  
  #' 'ctmeval_obs' will be the return variable in the end of this function. It is a
  #' list and has one list element per measured species. Each list element will have
  #' the structure of 'dummy_obs'.
  ctmeval_obs = list()
  
  #' 'dummy_obs' has the structure of one 'observationts' list which is return from
  #' a 'getobservationts' call of the 'ctmeval' package v 0.9.5.1. It has three 
  #' additional elements which are
  #'    $station$altitude,
  #'    $timeser$hour, and
  #'    $method_ref.
  #' 'dummy_obs' is the template for all elements in ctmeval_obs (copied for each 
  #' element) and is filled with all information that is equal for all measurements.
  #' These information are '$station' and '$type'. All other list members are created
  #' but set to NULL. 
  dummy_obs = list("station" = list("station_id"=emepdata$addDataInfo$`Station code`,
                                    "station_name"=emepdata$addDataInfo$`Station name`,
                                    "country"=substr(emepdata$addDataInfo$`Station code`,1,2),
                                    "latitude"=emepdata$addDataInfo$`Station latitude`,
                                    "longitude"=emepdata$addDataInfo$`Station longitude`,
                                    "altitude"=emepdata$addDataInfo$`Station altitude`),
                   "timeser" = list('time' = NULL,
                                    'hour' = NULL,
                                    'values' = NULL,
                                    'n' = NULL),
                   "substance" = NULL,
                   "unit" = NULL,
                   "matrix" = NULL,
                   "type" = ifelse(calc_mean, fun_apply, 'raw'))
  
  #' iterate all measured species/variables
  for(iVar in 1:emepdata$nVars) {
    #' copy dummy_obs and find out which species we are copying
    tmp_obs = dummy_obs
    tmp_varname = emepdata$measurements$titleVarsShort[iVar]
    
    #' copy meta data
    tmp_obs$substance = tmp_varname
    tmp_obs$unit = emepdata$measurements$units[iVar]
    tmp_obs$matrix = emepdata$measurements$matrices[iVar]
    tmp_obs$method_ref = emepdata$measurements$method_refs[iVar]
    
    #' copy times and values
    tmp_obs$timeser$time = emepdata$timing$times[,1]
    tmp_obs$timeser$hour = emepdata$timing$times[,2]
    tmp_obs$timeser$values = emepdata$measurements$variables[,iVar]
    tmp_obs$timeser$n = as.integer(rep(1, length(tmp_obs$timeser$values)))
    
    #' remove invalid values
    ### test
    ## xyz = matrix((matrix(1:12, ncol = 3)%in%c(1,5,9,2,3,6,11))-1, ncol = 3)
    ## as.logical(rowSums(xyz, na.rm = TRUE, dims = 1))
    tmp_invalid = as.logical(rowSums(matrix((matrix(emepdata$flags$numflags[,iVar,], ncol = 3)%in%vlevels)-1, ncol = 3), na.rm = TRUE, dims = 1))
    tmp_obs$timeser$values[tmp_invalid] = NA
    tmp_obs$timeser$n[tmp_invalid] = as.integer(0)
    
    #' do mean/sum calculations
    if (calc_mean) {
      #' daily mean/sum values
      if (mean_type == 'daily') {
        #' We only have to do something if the data is not already in daily
        #' resolution (emepdata$addDataInfo$`Resolution code` == '1d').
        if (emepdata$addDataInfo$`Resolution code` != '1d') {
          tmp_timeser = list('time' = NULL, 'hour' = NULL, 'values' = NULL, 'n' = NULL)
          tmp_timeser$time = unique(emepdata$timing$times[,1])
          nT = length(tmp_timeser$time)
          tmp_timeser$hour = rep(0, nT)
          tmp_timeser$values = rep(0, nT)
          tmp_timeser$n = rep(0, nT)
          
          for(iT in 1:nT) {
            this_time = tmp_timeser$time[iT]
            the_steps = (tmp_obs$timeser$time==this_time)
            tmp_timeser$values[iT] = apply(matrix(tmp_obs$timeser$values[the_steps], nrow = 1), MARGIN = c(1), FUN = fun_apply, na.rm = TRUE)
            tmp_timeser$n[iT] = sum(tmp_obs$timeser$n[the_steps], na.rm = TRUE)
          }
          tmp_obs$timeser = tmp_timeser
        }
        
        #' mean_type == emepdata$addDataInfo$`Resolution code`
      } else if (((mean_type == 'hourly') && (emepdata$addDataInfo$`Resolution code` == '1h')) ||
                 ((mean_type == 'weekly') && (emepdata$addDataInfo$`Resolution code` == '1w')) ||
                 ((mean_type == 'monthly') && (emepdata$addDataInfo$`Resolution code` == '1m'))) {
        warning('mean_type != "daily" is not implemented but "mean_type" == data resolution.')
        
        #' else ...
      } else {
        warning('mean_type != "daily" is not implemented. Raw data is returned.')
        tmp_obs$type = 'raw'
      }
    }
    
    #' add new observationts list to the return-list
    ctmeval_obs[[tmp_varname]] = tmp_obs
  }
  
  #' return the return-list
  return(ctmeval_obs)
}
