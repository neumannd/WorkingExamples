#' Insert data into the EMEP database
#'
#' This function reads in a EMEP text file 'file', which 
#' needs to be in the EBAS v1.1 format. The data will be written into the 
#' database defined by the DBaccess variable. A RODBC connection ('channel')
#' is opened and addFile.RODBC is called.
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
#' @param file character: path of the EMEP text file to import (path = dir/file)
#' @param removeDuplicates logical [TRUE]: the function removeDuplicates.emepdata() is applied on the emepdata before insertion
#' @param removeStatistics logical [TRUE]: the function removeStatistics.emepdata() is applied on the emepdata before insertion (variables with 'Statistics' attributes != 'arithmetic mean' will be removed)
#' @param forceCleanAndInsertProblematicFiles logical [FALSE]: If TRUE, problematic variables in files are removed and than the variables are inserted into the database.
#' @return list(): information whether the process was successful or not
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @format R Code
#' @export 
addFile <- function(file, removeDuplicates = TRUE, removeStatistics = TRUE, forceCleanAndInsertProblematicFiles = FALSE) {
  
  if ( !exists('DBaccess') ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not set.')
  if ( is.null(DBaccess$name) || is.null(DBaccess$uid) || is.null(DBaccess$pwd) ) stop('DBaccess = list(name = ..., uid = ..., pwd = ...) not correctly set.')
  
  channel <- odbcConnect(dsn=DBaccess$name, uid=DBaccess$uid, pwd=DBaccess$pwd) 
  return_val = addFile.RODBC(channel, file=file, removeDuplicates=removeDuplicates, removeStatistics=removeStatistics, forceCleanAndInsertProblematicFiles=forceCleanAndInsertProblematicFiles)
  close(channel)
  
  return(return_val)
  
}
