#' Insert data into the EMEP database
#'
#' This function reads in a EMEP text file 'file', which 
#' needs to be in the EBAS v1.1 format. The data will be written into the 
#' database to which an open RODBC connection exists given by 'channel'.
#' 
#' This function reads in a EMEP text file 'file', which 
#' needs to be in the EBAS v1.1 format. The data will be written into the 
#' database defined by the DBaccess variable. A RODBC connection ('channel')
#' is opened and addFile.RODBC is called.
#' 
#' If forceCleanAndInsertProblematicFiles is FALSE, some files will not be inserted (when there 
#' is at least one problematic variable present). This is tested by 
#' 'findProblematicAttribute.emepdata()'. See the documentation of that function
#' to see, which variables with which attributes might be problematic. If 
#' forceCleanAndInsertProblematicFiles is set to TRUE, the problematic variables will be removed
#' and the remaining variables will be inserted. The file will be marked as inserted incomplete.
#' 
#' Note:
#' If the file is not in version 1.1 of the EBAS format but in another version 
#' please test the read.emepFile(...) individually on that file.
#' 
#' @param channel RODBC: open ODBC data basebase connection
#' @param file character: path of the EMEP text file to import (path = dir/file)
#' @param removeDuplicates logical [TRUE]: the function removeDuplicates.emepdata() is applied on the emepdata before insertion
#' @param removeStatistics logical [TRUE]: the function removeStatistics.emepdata() is applied on the emepdata before insertion (variables with 'Statistics' attributes != 'arithmetic mean' will be removed)
#' @param forceCleanAndInsertProblematicFiles logical [FALSE]: If TRUE, problematic variables in files are removed and than the variables are inserted into the database.
#' @return list(): information whether the process was successful or not
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @export
#' @format R Code
addFile.RODBC <- function(channel, file, removeDuplicates = TRUE, removeStatistics = TRUE, forceCleanAndInsertProblematicFiles = FALSE) {
  ### initialize variables ----
  err = 0
  err_file = 0
  noInsert = FALSE
  file_id = -1
  fName = strsplit(file, '/')[[1]][length(strsplit(file, '/')[[1]])] 
  fName_old = paste(substr(fName,1,16), substr(fName,23,31), substr(fName,38,256), sep = '')
  file_name = paste("'", substr(fName,1,16), substr(fName,23,31), substr(fName,38,256), "'", sep="")
  general_file_name = paste("'", substr(fName, start=1, stop=8), "XXXXXXXX", substr(fName,23,31), substr(fName, start=38, stop=200), "'", sep="")
  
  ### proceed if the files actually exists ----
  fExists = file.exists(file)
  if (fExists) {
    ### Read EMEP input file, remove problematic variables and redo some dimensions ----
    emepdata = read.emepFile(file)
    
    if(removeStatistics) emepdata = removeStatistics.emepdata(emepdata)$new_data
    problematicData = findProblematicAttributes.emepdata(emepdata)
    if(length(problematicData$problemIndices) > 0) {
      tmpString = ''
      for (i1 in problematicData$problemIndices) {
        tmpString = paste(tmpString, problematicData$allVars[[i1]]$name, ': ', sep = '')
        for (i2 in setdiff(names(problematicData$allVars[[i1]]), 'name')) {
          tmpString = paste(tmpString, ', ', i2, ' = ', problematicData$allVars[[i1]][[i2]], sep = '')
        }
        tmpString = paste(tmpString, '; ', sep = '')
      }
      
      if(forceCleanAndInsertProblematicFiles) {
        emepdata = removeEntries.emepdata(emepdata, problematicData$problemIndices)
        warning(paste('Variables with problematic attributes in file ', file, ' were removed. Problematic variables were:: ', tmpString, sep = ''))
      } else {
        stop(paste('Problematic attributes of some variables in file ', file, '. Problematic variables are:: ', tmpString, sep = ''))
      }
    }
    
    if (removeDuplicates) emepdata <- removeDuplicates.emepdata(emepdata)$new_data
    
    if(emepdata$nVars == 0) {
      err_file = 0
      sgl_id = -1
      noInsert = TRUE
      nVars = 0
      nTimes = 0
      substances_short = c(" ")
      queryInsert <- ""
      err = 1
    } else {
      emepdata$filename = paste(substr(fName,1,16), substr(fName,23,31), substr(fName,38,256), sep = '')
      tmpDim = dim(emepdata$flags$numflags) 
      
      ## DO NOT DO THIS. The correct dimension might be c(tmpDim[1], 1, tmpDim[2]) or
      ## c(1, tmpDim[1], tmpDim[2]). 
      if ( length(tmpDim) == 2 ) {
        dim(emepdata$flags$numflags) = c(emepdata$nRowData, emepdata$nVars,
                                          length(emepdata$flags$numflags)/emepdata$nRowData/emepdata$nVars)
      }
      
      tmpDim = dim(emepdata$measurements$variables)
      if (is.null(tmpDim)) tmpDim = 0
      if (length(tmpDim) == 1) {
        dim(emepdata$measurements$variables) = c(emepdata$nRowData, emepdata$nVars)
      }
      
      ### write some EMEP meta data into other variables ----
      nVars = emepdata$nVars
      nTimes = emepdata$nRowData
      substances_short = emepdata$measurements$titleVarsShort
      
      station_id = paste("'", emepdata$addDataInfo[["Station code"]], "'", sep="")
      start_time = emepdata$timing$times[1,1]
      end_time = emepdata$timing$times[emepdata$nRowData,1]
      data_definition = paste("'", emepdata$addDataInfo[["Data definition"]], "'", sep="")
      set_type_code = paste("'", emepdata$addDataInfo[["Set type code"]], "'", sep="")
      regime = paste("'", emepdata$addDataInfo[["Regime"]], "'", sep="")
      station_code = paste("'", emepdata$addDataInfo[["Station code"]], "'", sep="")
      platform_code = paste("'", emepdata$addDataInfo[["Platform code"]], "'", sep="")
      tmp_startdate = emepdata$addDataInfo[["Startdate"]]
      startdate = paste("'", substr(tmp_startdate, 1, 4), "-", substr(tmp_startdate, 5, 6), "-", substr(tmp_startdate, 7, 8), "'", sep="")
      tmp_timeref = emepdata$addDataInfo[["Timeref"]]
      timeref = ifelse(is.null(tmp_timeref), "'00:00:00'", paste("'", substr(tmp_timeref, 1, 2), ":", substr(tmp_timeref, 4, 5), ":00'", sep=""))
      tmp_revision_date = emepdata$addDataInfo[["Revision date"]]
      revision_date = paste("'", substr(tmp_revision_date, 1, 4), "-", substr(tmp_revision_date, 5, 6), "-", substr(tmp_revision_date, 7, 8), "'", sep="")
      component = paste("'", emepdata$addDataInfo[["Component"]], "'", sep="")
      unit = paste("'", emepdata$addDataInfo[["Unit"]], "'", sep="")
      matrix = paste("'", emepdata$addDataInfo[["Matrix"]], "'", sep="")
      period_code = paste("'", emepdata$addDataInfo[["Period code"]], "'", sep="")
      resolution_code = paste("'", emepdata$addDataInfo[["Resolution code"]], "'", sep="")
      laboratory_code = paste("'", emepdata$addDataInfo[["Laboratory code"]], "'", sep="")
      instrument_type = paste("'", emepdata$addDataInfo[["Instrument type"]], "'", sep="")
      instrument_name = paste("'", emepdata$addDataInfo[["Instrument name"]], "'", sep="")
      method_ref = paste("'", emepdata$addDataInfo[["Method ref"]], "'", sep="")
      ext_lab_code = paste("'", emepdata$addDataInfo[["Ext. lab. code"]], "'", sep="")
      ext_meth_ref = paste("'", emepdata$addDataInfo[["Ext. meth. ref"]], "'", sep="")
      add_qualifier = paste("'", emepdata$addDataInfo[["Add. qualifier"]], "'", sep="")
      
      start_time_YYYYDDD = emepdata$timing$times[1,1]
      start_time_HH = emepdata$timing$times[1,2]
      end_time_YYYYDDD = emepdata$timing$times[nTimes,3]
      end_time_HH = emepdata$timing$times[nTimes,4]
      
      
      ### test whether the files was alreay imported; create file entry if not ----
      #' There are three different cases:
      #'  (a) file was never imported before
      #'  (b) file has benn imported but not completely
      #'  (c) file has been completely imported 
      #' In the case (c) we have to do nothing (noInsert = TRUE).
      #' In the cases (a) and (b) we have to proceed. But in case (a) we have to 
      #' create an database entry for the file, first.
      duplicateString_sgl_files = paste("SELECT sgl_id, file_id, complete FROM sgl_files WHERE ",
                                        "file_name=", file_name, ";", sep="")
      queryDuplicate_sgl_files = sqlQuery(channel, query=duplicateString_sgl_files)
      
      # case (b) or (c):
      if (dim(queryDuplicate_sgl_files)[1] > 0) {
        file_id = as.integer(queryDuplicate_sgl_files[1,"file_id"])
        sgl_id = as.integer(queryDuplicate_sgl_files[1,"sgl_id"])
        # case (c):
        if(queryDuplicate_sgl_files[1,"complete"]) noInsert = TRUE
        err_file=as.integer(-1)
        queryInsert <- ""
        # case (a)
      } else {
        # create a file entry in the database
        like_file_name = paste("'", substr(fName_old, start=1, stop=8), '%', substr(fName_old, start=17, stop=200), "'", sep="")
        duplicateString_files = paste("SELECT file_id FROM files WHERE ",
                                      "file_name LIKE ", like_file_name, ";", sep="")
        queryDuplicate_files = sqlQuery(channel, query=duplicateString_files)
        if (dim(queryDuplicate_files)[1] > 0) {
          file_id = as.integer(queryDuplicate_files[1,"file_id"])
          queryInsert <- ""
        } else {
          # insert file ... 
          insertString_files = paste("INSERT INTO files",
                                     " (file_name, station_id, ",
                                     "data_definition, set_type_code, regime, station_code, ",
                                     "platform_code, timeref, revision_date, ",
                                     "component, unit, matrix, period_code, resolution_code, ",
                                     "laboratory_code, instrument_type, instrument_name, ",
                                     "method_ref, ext_lab_code, ext_meth_ref, add_qualifier)",
                                     " VALUES(",
                                     " ", general_file_name, 
                                     ", ", station_id, 
                                     ", ", data_definition, 
                                     ", ", set_type_code, 
                                     ", ", regime, 
                                     ", ", station_code, 
                                     ", ", platform_code, 
                                     ", ", timeref, 
                                     ", ", revision_date, 
                                     ", ", component, 
                                     ", ", unit, 
                                     ", ", matrix, 
                                     ", ", period_code, 
                                     ", ", resolution_code, 
                                     ", ", laboratory_code, 
                                     ", ", instrument_type, 
                                     ", ", instrument_name, 
                                     ", ", method_ref, 
                                     ", ", ext_lab_code, 
                                     ", ", ext_meth_ref, 
                                     ", ", add_qualifier,
                                     ");", 
                                     sep="")
          queryInsert_files <- sqlQuery(channel, query=insertString_files)
          if (length(grep("ERROR", queryInsert_files)) == 0) { #NO ERROR
            queryGetID <- sqlQuery(channel, query=duplicateString_files)
            file_id = as.integer(queryGetID[1,"file_id"])
          } else { 
            err_file = as.integer(2)
            noInsert = TRUE
          }
        }
        
        
        if (!noInsert) {
          insertString_sgl_files = paste("INSERT INTO sgl_files",
                                         "(file_name, start_time_yyyyddd, start_time_hh, ",
                                         "end_time_yyyyddd, end_time_hh, startdate,",
                                         "file_id, n_timesteps, special_comment_present)",
                                         " VALUES(",
                                         " ", file_name, 
                                         ", ", start_time_YYYYDDD,
                                         ", ", start_time_HH, 
                                         ", ", end_time_YYYYDDD,
                                         ", ", end_time_HH, 
                                         ", ", startdate, 
                                         ", ", file_id,
                                         ", ", emepdata$nRowData,
                                         ", ", as.character(!(emepdata$specialInfo=="")),
                                         ");", 
                                         sep="")
          queryInsert_sgl_files <- sqlQuery(channel, query=insertString_sgl_files)
          
          if (length(grep("ERROR", queryInsert_sgl_files)) == 0) { #NO ERROR
            # everything o.k.
            get_sgl_id = sqlQuery(channel, query=duplicateString_sgl_files)
            print(get_sgl_id)
            sgl_id = get_sgl_id[1,"sgl_id"]
          } else { 
            err_file = as.integer(2)
            noInsert = TRUE
            sgl_id = -1
          }
        }
      }
    }
  } else { # EMEP data file does not exist
    err_file = 4
    sgl_id = -1
    noInsert = TRUE
    nVars = 0
    nTimes = 0
    substances_short = c(" ")
    queryInsert <- ""
  }
  
  if (!noInsert) {
    cat("add_file: calling addData\n")
    dOut <- addData.RODBC(channel, emepdata, file_id, sgl_id)
  } else {
    dOut <- list("err"=as.integer(0), "id"=as.integer(-1), "n"=as.integer(nVars*nTimes), 
                 "dims"=c(as.integer(0), as.integer(0)), "errN"=as.integer(0), 
                 "errs"=as.integer(0), "new_data"=0,
                 "complete_substances"=rep(FALSE, nVars), "new_substances" = rep(FALSE, nVars)
                 )
    if(exists('queryDuplicate_sgl_files')) {
      if (queryDuplicate_sgl_files[1,"complete"]) dOut$complete_substances = rep(TRUE, nVars)
    }
  }
  
  tmp_err = length(which(dOut$errs > 0)) + dOut$err
  if (tmp_err > 0 || err_file > 0) {
    err = err + as.integer(1)
  } 
  
  if (err <= 0 && length(problematicData$problemIndices) == 0) {
    completeQuery_f = paste("UPDATE sgl_files SET ",
                            "complete=TRUE",
                            " WHERE ",
                            "file_name=", file_name,
                            ";", sep="")
    queryUpdate = sqlQuery(channel, query=completeQuery_f)
    if (length(grep("ERROR", queryUpdate)) > 0) err = err + 8
  }
  
  
  if (err_file == 0) {
    read_file = "1"
    new_file = as.integer(1)
  } else {
    new_file = as.integer(0)
    if (err_file==4) { # ToDo???: Change
      read_file="No"
    } else {
      read_file="1"
    }
  }
  if(sum(dOut$complete_substances) == length(dOut$complete_substances)) complete_file = "1"
  else complete_file = "0"
  
  if (fExists && emepdata$nVars > 0) {
    outString = paste("add_file: database importing results::\n  ",
                      read_file, " file was read in containing ", nVars, " variables over ", nTimes, " time steps each. \n  ",
                      new_file , " of ", 1, " files and meta data sets were newly INSERTed into table SGL_FILES. \n  ",
                      if(length(problematicData$problemIndices) == 0) complete_file else 0, " of ", 1, " files and meta data sets in table SGL_FILES are complete. \n  ",
                      length(which(dOut$new_substances==TRUE)) , " of ", nVars, " variables were newly INSERTed into table F_SUBSTANCES. \n  ",
                      sum(dOut$new_substances*dOut$complete_substances) , " of ", nVars, " variables were newly and completely INSERTed into table F_SUBSTANCES. \n  ",
                      length(which(dOut$complete_substances==TRUE)) , " of ", nVars, " variables in table F_SUBSTANCES are complete. \n  ",
                      dOut$new_data, " of ", nTimes*nVars, " data sets (/measurement values) were newly INSERTed into table DATA. \n", 
                      "Problematic variables did ", if(length(problematicData$problemIndices) == 0) 'not exist.' else paste('did exist (hence: file NOT complete). ', length(problematicData$problemIndices), ' variables were removed.', sep = ''), ' \n', sep="")
  } else {
    if (!fExists) {
      outString = paste('add_file: File does not exist. No data were imported. File name::\n  ', file, sep = '')
      warning(paste('file did not exist: ', file, sep = ''))
    } else {
      outString = paste('1 file was read in containing 0 variables over 0 time steps each. \n',
                        "Problematic variables did ", if(length(problematicData$problemIndices) == 0) 'not exist.' else paste('did exist (hence: file NOT complete). ', length(problematicData$problemIndices), ' variables were removed.', sep = ''), ' \n', 
                        'No variables left after cleaning steps of file ', file, '\n', sep = '')
      warning(paste('No variables left after cleaning steps of file ', file, sep = ''))
    }
  }
  
  if (err <= 0) {
    outString = paste(outString, "No error occured. \n", sep = "")
  } else {
    outString = paste(outString, "Error(s) occured. \n", sep = "")
  }
  
  cat(outString)
  
  return(list(
    "file_id"=file_id,
    "sgl_id"=sgl_id,
    "file_name"=file_name,
    "substances_short"=substances_short,
    "data_ids"=dOut$ids,
    "n_file"=as.integer(1),
    "n_measurement"=nVars,
    "n_data"=dOut$n,
    "new_file"=new_file,
    "new_measurement"=length(which(dOut$complete==TRUE)),
    "new_data"=dOut$new,
    "dims_data"=dOut$dims,
    "err"=err,
    "err_file"=err_file,
    "err_data"=dOut$err,
    "errN_data"=dOut$err,
    "errs_data"=dOut$errs,
    "text"=outString
  )
  )
  
  # err=-1 => data is already present
  # err=+1 => some unknown error occured
  # err=+2 => INSERT did not work properly
  # data_err=+4 => (length(measurement_id's) != nVars) in addData
  # file_err=+4 => file does not exist
  
}
