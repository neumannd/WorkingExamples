#' private: Insert data into the EMEP database (please use addFile)
#'
#' Please use addFile() to add data to the database if you 
#' are not really sure what you are doing. Adds data (emepdata) 
#' into the database given by a open RODBC connection 
#' (channel).
#' 
#' @param channel RODBC: open ODBC data basebase connection
#' @param emepdata list: EMEP data to write into the database
#' @param file_id_IN integer: id of the entry in the files table corresponding to the currently being imported data set
#' @param sgl_id_IN integer: id of the entry in the sgl_files table corresponding to the currently being imported data set
#' @return list(): information whether the process was successful or not
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
addData.RODBC <- function(channel, emepdata, file_id_IN, sgl_id_IN) {
  # initialize some variables
  nVars = emepdata$nVars
  nRows = emepdata$nRowData
  complete_substances = rep(FALSE, nVars)
  new_substances = rep(FALSE, nVars)
  
  errs = as.integer(rep(-1, nVars*nRows))
  dim(errs) = c(nRows, nVars)
  
  ids = as.integer(rep(0, nVars*nRows))
  dim(ids) = c(nRows, nVars)
  
  
  if (length(sgl_id_IN) != nVars && length(sgl_id_IN) != 1) {
    # some problem with the data
    err = as.integer(4)
  } else {
    err = as.integer(0)
    
    file_id = format(as.integer(file_id_IN))
    if (length(sgl_id_IN) == 1 && nVars > 1) {
      sgl_ids = as.integer(rep(sgl_id_IN, nVars))
    } else {
      sgl_ids = sgl_id_IN
    }
    
    #
    tmp_id=as.integer(0)
    tmp_err=as.integer(0)
    
    station_id = paste("'", emepdata$addDataInfo[["Station code"]], "'", sep="")
    
    # Go through all variables except of those which measurements were not
    # inserted correctly into the measurements table. If varibale i was not
    # inserted correctly measurement_id_IN is set to -1.
    if(length(which(sgl_id_IN==-1))>0) {
      cols = (1:nVars)[-which(sgl_id_IN==-1)]
    } else {
      cols = 1:nVars
    }
    
    # iterate all variables (= columns) of the EMEP data set
    for (iCol in cols) {
      # extract variable information
      sgl_id = format(as.integer(sgl_ids[iCol]))
      substance_short = paste("'", emepdata$measurements$titleVarsShort[iCol], "'", sep="")
      unit = paste("'", emepdata$measurements$units[iCol], "'", sep="")
      matrix = paste("'", emepdata$measurements$matrices[iCol], "'", sep="")
      method_ref = paste("'", emepdata$measurements$method_refs[iCol], "'", sep="")
      
      # initialise sf_remove
      #  Remove f_substance if it exists and is not complete. => In this case, 
      #  sf_remove is set to TRUE.
      sf_remove = FALSE
      sf_insert = TRUE
      #
      #' We have three possible situations:
      #'  (a) Entry in f_substance exists and is complete (sf_remove = FALSE, sf_insert = FALSE)
      #'        - do nothing
      #'  (b) Entry in f_substance exists and is not complete (sf_remove = TRUE, sf_insert = TRUE)
      #'        - remove rows in data table which have the corresponding sf_id
      #'        - insert the new data (if no error arose during removal)
      #'  (c) Entry in f_substance exists not (sf_remove = FALSE, sf_insert = TRUE)
      #'        - insert the data
      
      # look whether the substance exists
      sf_exists = existsFSubstance.RODBC(channel, sgl_id, substance_short, matrix, method_ref)
      if (!sf_exists$exists) {
        sf_exists = addFSubstance.RODBC(channel, sgl_id, substance_short, matrix, method_ref) # case (c)
      } else {
        if (!sf_exists$complete) sf_remove = TRUE # case (b)
        else sf_insert = FALSE  # case (a)
      }
      
      sf_id = sf_exists$sf_id
      
      # Remove all time steps in the data table of the data base if the
      # variable entry already existed in f_substance and was incomplete.
      # In this situation remove_string was set to TRUE, above.
      if (sf_remove) {
        cat('  addData: Removing one incomplete data set and inserting it again.\n')
        remove_return = removeData.RODBC(channel, sf_id)
        if (remove_return$err_code != 0) {
          warning(paste('addData.RODBC: Database entries could not be removed properly. Skipping insertion of data. Data set: ',
                        emepdata$filename, ", ",
                        sgl_id, " (sgl_id), ",
                        sf_id, " (sf_id), ",
                        substance_short, ", ",
                        matrix, ", ",
                        method_ref, ", ",
                        sep = ""))
          sf_insert = FALSE
        }
      }
      
      if (sf_insert) {
        new_substances[iCol] = TRUE
        # iterate all time steps and insert them into the database.
        for (iRow in 1:nRows) {
          start_time_YYYYDDD = emepdata$timing$times[iRow,1]
          start_time_HH = emepdata$timing$times[iRow,2]
          end_time_YYYYDDD = emepdata$timing$times[iRow,3]
          end_time_HH = emepdata$timing$times[iRow,4]
          
          value = format(emepdata$measurements$variables[iRow,iCol], scientific=TRUE)
          numflag = as.integer(emepdata$flags$numflags[iRow,iCol,]) 

          insertString = paste("INSERT INTO data",
                               "(sf_id, station_id, substance_short, matrix, unit, ", 
                               "start_time_YYYYDDD, start_time_HH, end_time_YYYYDDD, end_time_HH, ",
                               "value, numflag1, numflag2, numflag3, file_id)",
                               " VALUES(",
                               sf_id, ", ", station_id, ", ", substance_short, ", ",
                               matrix, ", ", unit, ", ", 
                               start_time_YYYYDDD, ", ", start_time_HH, ", ", end_time_YYYYDDD, ", ", end_time_HH,  ", ",
                               value, ", ", numflag[1], ", ", numflag[2], ", ", numflag[3], ", ", file_id, ");",
                               sep="")
          
          queryInsert <- sqlQuery(channel, query=insertString)
          if (length(grep("ERROR", queryInsert)) == 0) { # NO ERROR
            tmp_id = as.integer(-1)
            tmp_err = 0
          } else { # ERROR
            tmp_id = as.integer(-1)
            tmp_err = as.integer(2)
          }
          errs[iRow, iCol] = tmp_err
          ids[iRow, iCol] = tmp_id
        }
      }
      
      if (length(which(errs[,iCol]>0))==0) {
        
        complete_substances[iCol] = TRUE
        sf_exists = completeFSubstance.RODBC(channel, sf_exists$sf_id)
        if(sf_insert) {
          cat(paste("  addData: Time series was properly inserted (sgl_id=", sgl_id, ", sf_id=", sf_id,").\n", sep = ''))
        } else {
          cat(paste("  addData: Time series did already exist and was complete (sgl_id=", sgl_id, ", sf_id=", sf_id,").\n", sep = ''))
        }
          
      } else {
        cat(paste("  addData: The time series could not be inserted completely (sgl_id=", sgl_id, ", sf_id=", sf_id,"). See warning for details.\n", sep = ''))
        warning(paste('addData.RODBC: The full time series could not be inserted properly. Data set: ',
                      emepdata$filename, ", ",
                      sgl_id, " (sgl_id), ",
                      sf_id, " (sf_id), ",
                      substance_short, ", ",
                      matrix, ", ",
                      method_ref, ".",
                      sep = ""))
      }
    }
    
    if (length(which(errs>0))>0) err = err + 1
  }
  
  return(list(
    "err"=err, "id"=ids, "n"=nRows*nVars, "dims"=c(nRows, nVars), 
    "errN"=length(which(errs>0)), "errs"=errs, "new_data"=length(which(errs==0)),
    "complete_substances"=complete_substances, "new_substances" = new_substances))
}
