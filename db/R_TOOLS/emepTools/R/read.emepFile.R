#' Import a text file in the EBAS v1.1 format (EMEP data file) into R
#' 
#' Opens and reads an EMEP ASCII file. The data is separated from the
#' header. Both sets of information are put into returned list. The time
#' of measurements in the output list is formated as the time in CMAQ
#' result files.
#' 
#' 
#' \strong{emep file structure}
#'
#'  EMEP measurement files are written as ASCII text files in a modified 
#' NASA-Ames 1001 format. A nice description can be found at
#' http://www.eusaar.net/files/data/nasaames/index.html . See also
#' http://ebas-submit.nilu.no/ for some other informations.
#'
#'  Currently all text files which are exported from the EBAS system have the 
#' same structure. At first come several lines overhead. After that the 
#' headlines for different columns of data are given in one lines. In the next
#' line the data starts. Each lines of data contains measurements at one date.
#'
#' The different columns contain start- and end-date of measurements, the 
#' measured values and sometimes flags. This flags indicate the quality of the
#' measurement. See http://www.nilu.no/projects/ccc/flags/index.html for a list
#' of flags.
#'
#' Each data column has a short and a long name. In the file header a list of
#' all measured variables is given in long names. The actual column headlines
#' are short names. 
#'
#' File Structure: 
#'   line              1: (INT)rowData INT
#'                         line in which headlines of columns of data are; 
#'                         some integer
#'                                           search in code for BLOCK01
#'   lines       2 to  4: dataOrigin
#'                       some information on the source of the data (which 
#'                         agency etc.)
#'                                           search in code for BLOCK02
#'   line              5: whereToFind
#'                       in which databases is this data?
#'                                           search in code for BLOCK03
#'   line              6: INT INT
#'                       two integers of unknown function
#'                                           search in code for BLOCK04
#'   line              7: YYYY MM DD  YYYY MM DD
#'                       Two dates are in this line. The dates are saved as
#'                         Strings and Integers
#'                       The first data is the data, when the first observation
#'                         was performed.
#'                       The second data is the revision data of the instrument
#'                         (I think so)
#'                       twoDatesString as String (YYYY MM DD)
#'                       twoDatesInt as Integer (YYYYDDD) DDD = day of year
#'                                           search in code for BLOCK05
#'   line              8: length of time step, dt
#'                       Daily data: dt = 1
#'                       Weekly data: dt = 7
#'                       Hourly data:
#'                               dt = 1 (unit hours)
#'                               dt = 0.041667 (unit days)
#'                                           search in code for BLOCK06
#'   line              9: STR
#'                       explanation to the line before
#'                                           search in code for BLOCK07
#'   line             10: nCols-1
#'                       Number of lines with information to data colums. One
#'                        line for each colums with data. For the first column
#'                        there is no description. Therefore this number is the
#'                        "number of columns" - 1
#'                                           search in code for BLOCK08
#'   line             11: FLOATs
#'                       format of data values
#'                                           search in code for BLOCK09
#'   line             12: FLOATs
#'                       max (?) of data values
#'                                           search in code for BLOCK10
#'   line 13 to 12+nCols: STR
#'                       Description of the data columns later. Each description
#'                        is a comma separated list of values:
#'                        1.           column name (long version)
#'                        2.           unit
#'                        3., 4., ...  further information
#'                       Further information is partly processed #' NEW_v09_001
#'                                           search in code for BLOCK11
#'   line       13+nCols: 0
#'                       This may be also != 0. But I never had this case.
#'                        Therefore I ignore it here. #' NEW_v09_001
#'                                           search in code for BLOCK12
#'   line       14+nCols: nAddDataInfo+1
#'                       "Current line" + "this value" = "line number with
#'                        column headlines"
#'                       In the following lines in between is additional
#'                        information for this data set. It has the format
#'                        "[DATA TYPE]: ADD DATA".
#'                                           search in code for BLOCK13
#'   line     posRowData: titlesShort
#'                       titles of data columns; nCols strings separated by
#'                        each one space (" ");
#'                       (posRowData = 14 + nCols + nAddDataInfo)
#'                                           search in code for BLOCK14
#'   line   posRowData+1: data[1,]
#'   line   posRowData+2: data[2,]
#'   line   posRowData+i: data[i,]
#'                       The data is read in as strings because some values
#'                        may cause problems when they are represented as
#'                        floating point numbers.
#'
#' end of file structure
#'
#' 
#' @param file character: path of the EMEP text file to import (path = dir/file)
#' @return emep_file list(): Contains all information from the file in
#'    a list with sub lists. Please look to the end of this function
#'    for the structure of the list.
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note This is the heart of this package. 
#' @format R Code
#' @export 
#' 
read.emepFile <- function(file) {
  fName = strsplit(file, '/')[[1]][length(strsplit(file, '/')[[1]])] 
  
  ## +--------------------------------------------+
  ## | SET VARIABLES
  ## +--------------------------------------------+
  ## | CONTENT
  ## |  ~ Indexing and Line and Column number variables
  ## |  ~ Variables for file content
  ## |  ~ Temporary Variables
  ## |  ~ 
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Indexing and Line and Column number variables
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  nCols=4    # Number of colums (start time, end time, measurements and flags)
  nVars=1    # Number of measurement variables
  nFlags=1   # Number of flag variables
  # nCols == 2 + nVars + nFlags
  
  nRows = 0                 # number of rows in the file
  posRowData = 2            # row number in which headlines of data columns
  #  start; in posRowData+1 the real data starts
  nRowData = 365            # number of rows with data (= nRows - posRowData)
  nSpecialInfo =  0         # number of rows with not-planned information 
  #  regarding the data (standard = 0)
  # In the NILU format description it is denoted as
  # 'special comment line'
  ## NEW_v09_002 : variable added
  nAddDataInfo = 0          # number of rows with additional information 
  #  regarding the data (such as instrument, 
  #  compartment) (standard = 23) 
  # In the NILU format description it is denoted as
  ## NEW_v09_002 : standard value changed
  # 'normal comment line'
  nRowsColDescr = 3         # = nCols - 1
  
  # for testing: nVars + nNumflags + 2 == nCols
  nVars = 0                 # number of variables in the file
  nNumflags = 0             # number of numFlags in the file
  
  rowCounter = 0            # current row
  
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Variables for file content
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Arrays which are initialised now:
  dataOrigin = c("", "", "") # Length should be kept!
  whereToFind = c("")            # Length is variable (= number of databases in which this data is present)
  twoDatesString = c("0000-00-00", "0000-00-00")
  twoDatesInt = c(1900000, 1900000)
  specialInfo = list()        # special comments # NEW_v09_003
  addDataInfo = list()        # ADDitional DATA INFOrmation (regarding the whole data set)
  
  # Arrays which are later initialized
  # units
  # matrices
  # method_refs
  # titlesShort
  # titlesLong
  # addColInfo      # ADDitional COLumn INFOrmation (individual per column)
  # numberFormat1
  # numberFormat2
  
  # Day Of Year
  refDate = 1900000
  dt = 0      # time step of the data
  
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Temporary Variables
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # tmpInt
  # tmpChar1
  # tmpChar2
  i1 = 0
  i2 = 0
  rowCounter = 0
  
  
  
  ## +--------------------------------------------+
  ## | OPEN FILE AND READ DATA
  ## +--------------------------------------------+
  ## | CONTENT
  ## |  ~ Open File and do preparations
  ## |  ~ Read File
  ## |  ~ Close File
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Open File and do preparations
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # open file
  fileHandle <- file(file, open="rt")
  
  # count lines in file
  if (isOpen(fileHandle)) {
    nRows = 0
    while (length(readLines(fileHandle, n=1)) > 0) {
      nRows = nRows + 1
    }
    # close and re-open file to reset the line pointer to 1
    close(fileHandle)                    # close file
    fileHandle <- file(file, open="rt") # re-open file
  }
  
  if (isOpen(fileHandle)) {
    cat(paste("read.emepFile: opening file and reading (", fName, ")\n", sep = ""))
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # ~ Read File
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    rowCounter = 0                # reset row counter
    # read two integers in one row
    #  first val = rowCounter: line in which headlines of columns of data are 
    #  second val:             some integer
    rowCounter = rowCounter + 1
    tmpInt <- scan(fileHandle, what=integer(), nmax=2, nlines=1, sep=" ", quiet=TRUE)
    rowData = tmpInt[1]
    nRowData = nRows - rowData
    #                         search in file structure description for BLOCK01
    
    # reads three lines of text
    #  dataOrigin: some information on the source of the data
    rowCounter = rowCounter + 3
    dataOrigin = scan(fileHandle, what=character(), nmax=3, sep="\n", quiet=TRUE)
    #                         search in file structure description for BLOCK02
    
    # Reads one line (line 5) with the information in which data bases
    # this data is also present
    rowCounter = rowCounter + 1
    whereToFind = scan(fileHandle, what=character(), nlines=1, sep=" ", quiet=TRUE)
    #                         search in file structure description for BLOCK03
    
    # reads two integers in one line; ignore them
    #  two integers of unknown function
    rowCounter = rowCounter + 1
    tmpInt <- scan(fileHandle, what=integer(), nmax=2, nlines=1, sep=" ", quiet=TRUE)
    #                         search in file structure description for BLOCK04
    #print("BLOCK04")
    
    # reads two dates in the format "YYYY MM DD" from one line
    # The dates are saved as Strings and Integers
    #  The first data is the data, when the first observation was performed.
    #  The second data is the revision data of the instrument (I think so).
    rowCounter = rowCounter + 1
    # read values; do not use sep=" "; Why? Between the date there is more
    #  than one space " ". If we use sep=" " we get empty fields in the array
    #  tmpChar.
    tmpChar <- scan(fileHandle, what=character(), nlines=1, quiet=TRUE)
    # twoDatesString as String (YYYY MM DD)
    twoDatesString = c(paste(tmpChar[1], tmpChar[2], tmpChar[3], sep = "-"),
                       paste(tmpChar[4], tmpChar[5], tmpChar[6], sep = "-")
    )
    # twoDatesInt as Integer (YYYYDDD) DDD = day of year
    tmpInt = as.integer(tmpChar)
    twoDatesInt[1]=tmpInt[1]*10^3+1+julian(
      as.Date(paste(tmpChar[1], tmpChar[2], tmpChar[3], sep="-")), 
      origin=as.Date(paste(tmpChar[1], "01-01", sep="-"))
    )
    twoDatesInt[2]=tmpInt[4]*10^3+1+julian(
      as.Date(paste(tmpChar[4], tmpChar[5], tmpChar[6], sep="-")), 
      origin=as.Date(paste(tmpChar[4], "01-01", sep="-"))
    )
    # Set the reference date for getting the correct observation times later.#
    refDate = twoDatesInt[1]
    #                         search in file structure description for BLOCK05
    #print("BLOCK05")
    
    # read dt; dt is given in days and the unit of time steps in the data is
    #  days except dt==1 AND "Resolution code"==1h (This value is given in the
    #  "addDataInfo" variable below.). In the latter case the time steps are 
    #  given in hours. See above in the file description for further details.
    rowCounter = rowCounter + 1
    dt = scan(fileHandle, what=numeric(), nmax=1, nlines=1, quiet=TRUE)
    #                         search in file structure description for BLOCK06
    #print("BLOCK06")
    
    # read one line which we do not need
    #  explanation to the line before
    rowCounter = rowCounter + 1
    tmpChar1 = scan(fileHandle, what=character(), nmax=1, nlines=1, sep="\n", quiet=TRUE)
    #                         search in file structure description for BLOCK07
    #print("BLOCK07")
    
    # read number of columns-1
    #  Number of lines with information to data colums.
    rowCounter = rowCounter + 1
    nRowsColDescr = scan(fileHandle, what=integer(), nmax=1, nlines=1, sep=" ", quiet=TRUE)
    nCols = nRowsColDescr + 1
    #                         search in file structure description for BLOCK08
    #print("BLOCK08")
    
    # read first and second set of number formats (each in one line)
    #  first line:  format of data values
    #  second line: max (?) of data values
    rowCounter = rowCounter + 2
    numberFormat1 = scan(fileHandle, what=double(), nmax=nRowsColDescr, nlines=1, sep=" ", quiet=TRUE)
    numberFormat2 = scan(fileHandle, what=double(), nmax=nRowsColDescr, nlines=1, sep=" ", quiet=TRUE)
    #                         search in file structure description for BLOCK09
    #                         search in file structure description for BLOCK10
    #print("BLOCK09")
    
    # read the next "nRowsColDescr" lines to get column titles and units
    #  Description of the data columns later. Each description is a comma 
    #  separated list of values:
    #   1.          column name (long version)
    #   2.          unit
    #   3., 4., ... further information
    rowCounter = rowCounter + nRowsColDescr
    tmpChar1 = scan(fileHandle, what="character", nmax=nRowsColDescr, nlines=nRowsColDescr, sep="\n", quiet=TRUE)
    
    # initialise arrays for data
    units = rep("", nCols)
    matrices = rep("", nCols)
    method_refs = rep("", nCols)
    titlesShort = rep("", nCols)
    titlesLong = rep("", nCols)
    addColInfo = array(list(), dim = nCols)
    
    # First column will be for variable 'start_time' which is not present here.
    # Therefore we place the block number n in tmpChar2 on position n+1 in the
    # 'titlesLong', 'units' and 'addColInfo'.
    for (i1 in 2:nRowsColDescr) {
      tmpChar2 = strsplit(tmpChar1[i1-1], split=", ")[[1]]
      titlesLong[i1] = tmpChar2[1]
      i2shift = 0
      tmpInt = length(tmpChar2)
      addColInfo[[i1]] = list()
      
      if (tmpInt >= 3 && (tmpChar2[2]=='instrument internal' || tmpChar2[2]==" ")) i2shift = 1
      
      units[i1] = tmpChar2[2+i2shift]
      
      if (tmpInt > 2 + i2shift) {
        for (i2 in (3+i2shift):tmpInt) {
          tmpChar3 = strsplit(tmpChar2[i2], split = "=")[[1]]
          addColInfo[[i1]][[tmpChar3[1]]] = tmpChar3[2]
        }
        
        # Look for further variables which are set in the additional column
        # information and which are important for us.
        # Currently, the value of 'Matrix' is important - if set. This is 
        # important, because of two cases:
        #  a) The component 'main_air_chem' is measured which may inculde gas
        #     and particle phase substances. If measurements of at least one
        #     gas phase substance are in a file the overall matrix is set to
        #     "air". Nevertheless, "aerosol" or "pm" species are in the file.
        #     In this situation the matrix of the non-"air" species is set in
        #     the additional information.
        #  b) Measurements in the aerosol phase are performed and per species
        #     two different particles sizes are measured. Both measurements
        #     are in one file and in the additional column information the
        #     matrix is set per species.
        # Also later important may be the value of "Method ref". In some cases
        # it is set in the additional column in formations. It could be that
        # based on this value one can identify the measured size of particles.
        if( "Matrix"%in%names(addColInfo[[i1]]) ) matrices[i1] = addColInfo[[i1]]$Matrix
        if( "Method ref"%in%names(addColInfo[[i1]]) ) method_refs[i1] = addColInfo[[i1]][["Method ref"]]
      }
    }
    #                         search in file structure description for BLOCK11
    #print("BLOCK11")
    
    # read the number of special comments and the special comments itself
    #  first row:    integer, number of special comments (nSpecialInfo)
    #                 usually: nSpecialInfo == 0
    #  further rows: special comments as strings
    rowCounter = rowCounter + 1
    nSpecialInfo = scan(fileHandle, what=integer(), nmax=1, nlines=1, sep="\n", quiet=TRUE)
    if (nSpecialInfo > 0) {
      rowCounter = rowCounter + nSpecialInfo
      # put all special comments into on string separated by ';; '
      specialInfo = paste(
        scan(fileHandle, what=character(), nmax=nSpecialInfo, nlines=nSpecialInfo, sep="\n", quiet=TRUE),
        collapse = ";; "
      )
    } else {
      specialInfo = ""
    }
    ##                         search in file structure description for BLOCK12a
    ##print("BLOCK12a")
    
    # read the number of normal comments
    #  first row:    integer, number of normal comments (nAddDataInfo)
    #                 usually: nAddDataInfo == 23  
    rowCounter = rowCounter + 1
    nAddDataInfo = scan(fileHandle, what=integer(), nmax=1, nlines=1, sep="\n", quiet=TRUE) - 1
    ##                         search in file structure description for BLOCK12b
    ##print("BLOCK12b")
    
    # read additional data for this data set from (nAddDataInfo-1) lines
    # In the following nAddDataInfo-1 lines is additional information for 
    # this data set. It has the format "[DATA TYPE]: ADD DATA".
    rowCounter = rowCounter + nAddDataInfo
    tmpChar1 = scan(fileHandle, what=character(), nmax=nAddDataInfo, nlines=nAddDataInfo, sep="\n", quiet=TRUE)
    for (i1 in 1:nAddDataInfo) {
      tmpChar2 = strsplit(tmpChar1[i1], split=":[ ]*")[[1]]
      addDataInfo[[tmpChar2[1]]] = tmpChar2[2]
    }
    #                         search in file structure description for BLOCK13
    #print("BLOCK13")
    
    # read short titles
    # titles of data columns; nCols strings separated by each one space (" ");
    rowCounter = rowCounter + 1
    titlesShort = scan(fileHandle, what=character(), nmax=nCols, nlines=1, quiet=TRUE)
    #                         search in file structure description for BLOCK14
    #print("BLOCK14")
    
    # read data
    data = rep(0.0, nCols*nRowData)  
    dim(data) = c(nRowData, nCols)
    for (i1 in 1:nRowData) {
      rowCounter = rowCounter + 1
      if (rowCounter >= nRows) cat("read.emepFile: reading last line\n")
      data[i1,] =  scan(fileHandle, what=character(), nmax=nCols, nlines=1, quiet=TRUE)
    }
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # ~ Close File
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    close(fileHandle)
  }
  
  ## +--------------------------------------------+
  ## | POSTPROCESS THE READ INFORMATION
  ## +--------------------------------------------+
  ## | CONTENT
  ## |  ~ Work on first column
  ## |  ~ Special case: Only one variable
  ## |  ~ Separate variables and numflags
  ## |  ~ Reformat Times
  ## |  ~ 
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Work on first column
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # start_time should have the same unit as end_time
  units[1] = units[2]
  titlesLong[1] = titlesShort[1]
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Special case: Only one variable
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## special case: four columns => titles == c("start_time", "end_time", "value", "numflag")
  ## We want "value" and "numflag" to be replaced by the true name of the 
  ##  measured variable.
  if (titlesShort[3] == "value") {
    print('Special case: only one variable')
    
    # get and set title of column 3 = variable name
    titlesShort[3] = convertSubstanceName(addDataInfo$Component, "shortDB")
    titlesLong[3] = convertSubstanceName(addDataInfo$Component, "long")
    
    # set numflag to a sensible name
    if (nCols == 4) {
      if (titlesShort[4] == "numflag") {
        titlesShort[4] = paste("numflag", titlesShort[3], sep="_")
        titlesLong[4] = paste("numflag", titlesLong[3], sep=" ")
      } else {
        print("Column 3 is named 'value' and column 4 exists but no numflag exists. Strange ...")
      }
    } else {
      print("Column 3 is named 'value' but no culumn 4 exists. Strange ...")
    } 
  }
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Separate variables and numflags
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## If one numflag-column corresponds to more than one measurement column
  ##  it is not named numflag_SUBSTANCE but only numflag.
  ## example        IS: no2 flag_no2 so4 xso4 flag
  ## example SHOULD BE: no2 flag_no2 so4 flag_so4 xso4 mflag_xso4
  # indices of "numflag" elements
  posNumflags = grep("flag", titlesShort)
  # indices of variables (not numflag and no date)
  posVars = (1:nCols)[-posNumflags][c(-1, -2)]
  nNumflags = length(posNumflags)
  nVars = nCols - 2 - nNumflags # should be == length(posVars)
  
  # Copy variables/measurements from DATA into VARIABLES
  titleVarsShort=titlesShort[posVars]
  titleVarsLong=titlesLong[posVars]
  for (i1 in 1:nVars) {
    titleVarsShort[i1] = convertSubstanceName(titlesShort[posVars[i1]], "shortDB")
    titleVarsLong[i1] = convertSubstanceName(titlesLong[posVars[i1]], "long")
  }
  
  units = units[posVars]
  matrices = matrices[posVars]
  method_refs = method_refs[posVars]
  addVarInfo = addColInfo[posVars]
  variables = as.double(data[,posVars])
  dim(variables) = dim(data[,posVars])
  if (nRowData == 1) dim(variables) = c(1, length(variables))
  
  # Create arrays to fill in numflag data later
  numflags = rep(0.0, length(variables)*3)
  
  if (nVars!=1) {
    dim(numflags) = append(dim(variables), 3)
  } else {
    dim(numflags) = c(length(variables), 1, 3)
    dim(variables) = c(length(variables), 1)
  }
  
  titleFlagsShort = rep("", nVars)
  titleFlagsLong = rep("", nVars)
  
  # Copy flags from DATA into NUMFLAGS
  i2 = 1
  for (i1 in 1:nVars) {
    numflags[,i1,1] = as.integer(substr(data[,posNumflags[i2]],3,5))
    numflags[,i1,2] = as.integer(substr(data[,posNumflags[i2]],6,8))
    numflags[,i1,3] = as.integer(substr(data[,posNumflags[i2]],9,11))
    
    numflags[is.na(numflags[,i1,2]),i1,2] = as.integer(0)
    numflags[is.na(numflags[,i1,3]),i1,3] = as.integer(0)
    
    titleFlagsShort[i1] = paste("flag", titleVarsShort[i1], sep="_")
    titleFlagsLong[i1] = paste("flag", titleVarsLong[i1], sep=" ")
    
    if (posVars[i1] + 1 == posNumflags[i2]) {
      i2 = i2 + 1
    }
    
    # Fill empty slots in 'matrices' and 'method_refs'
    if ( matrices[i1] == "") {
      matrices[i1] = addDataInfo$Matrix
    }
    
    if ( method_refs[i1] == "") {
      method_refs[i1] = addDataInfo[["Method ref"]]
    }
  }
  
  dim(numflags) = c(nRowData, nVars, 3)
  dim(variables) = c(nRowData, nVars)
  
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ Reformat times
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create arrays for reformatted times of measurements.
  titleTimes = titlesShort[c(1,2)]
  tmpTimes=array(0.0, dim = c(nRowData, 2))
  times=array(as.integer(0.0), dim = c(nRowData, 4))
  
  # Reference time in hours. Some daily measurements - as sometimes SO2 - are 
  #  measured at 6 o'clock UTC in the morning whereas other daily measurements
  #  are performed at 0 o'clock. This time is given in TIMEREF (in hours). We
  #  need to add it two the first two columns of the data array (start and 
  #  stop time).
  # ToDo: UTC or CST?
  if (is.null(addDataInfo$Timeref)) {
    timeref = 0
  } else {
    timeref = as.numeric(substr(addDataInfo$Timeref, 1, 2)) + (as.numeric(substr(addDataInfo$Timeref, 4, 5)))/60
  }
  if (addDataInfo[["Resolution code"]] == "1h" && dt == 1) {
    # Special case: hourly measurements and dt==1.
    #  In this case the time steps in the data are given in hours. Otherwise
    #  their are given in days.
    tmpTimes[,1]=as.integer(floor((as.double(data[,1])+timeref)/24)) # TODO???
    tmpTimes[,2]=as.integer(floor((as.double(data[,2])+timeref)/24))
    times[,2]=as.integer(round((as.double(data[,1])+timeref)%%25))
    times[,4]=as.integer(round((as.double(data[,2])+timeref)%%25))
  } else {
    # Normal case: Time steps in the data given in days. 
    tmpTimes[,1]=as.integer(floor(as.double(data[,1])+timeref/24))
    tmpTimes[,2]=as.integer(floor(as.double(data[,2])+timeref/24))
    times[,2]=as.integer(round((as.double(data[,1])-tmpTimes[,1])*24+timeref)%%25)
    times[,4]=as.integer(round((as.double(data[,2])-tmpTimes[,2])*24+timeref)%%25)
  }
  # Why FLOOR and not ROUND? Assume we have the day 39.986111. If we use
  # ROUND and no further IF-statements we get day 39 and hour 0 (Hour 23.6666
  # is rounded up to 24 and set to ZERO by %%24) which is
  # obviously wrong. To avoid IF-statements we now use FLOOR and get day 39 
  # and hour 23.
  
  times[,1] = as.integer(reworkTiming(tmpTimes[,1], refDate))
  times[,3] = as.integer(reworkTiming(tmpTimes[,2], refDate))
  
  # Test whether time = 24 o'clock. Then we increment the day by one 
  # and set the time to 0.
  for(i1 in 1:nRowData) {
    if ( times[i1,2] == 24) {
      times[i1, 2] = 0
      times[i1, 1] = times[i1, 1] + 1
    }
    
    if ( times[i1,4] == 24) {
      times[i1, 4] = 0
      times[i1, 3] = times[i1, 3] + 1
    }
  }
  
  cat("read.emepFile: processing of data finished\n")
  
  ## +--------------------------------------------+
  ## | FINALISE AND RETURN
  ## +--------------------------------------------+
  ## | CONTENT
  ## |  ~ remove variables
  ## |  ~ set temporary variables for returning
  ## |  ~ return data
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ remove variables
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  rm(i1)
  rm(i2)
  rm(fileHandle)
  rm(tmpChar)
  rm(tmpChar1)
  rm(tmpChar2)
  rm(tmpInt)
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ set temporary variables for returning
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (is.null(addDataInfo$Timeref)) {
    tod = as.integer(c(0,0))
  } else {
    tod = as.integer(strsplit(addDataInfo$Timeref, split="_")[[1]])
  }
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~ return data
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  return(list("filename"=fName,
              "timing"=list("titleTimes" = titleTimes,
                            "times" = times,
                            "resolution" = addDataInfo[["Resolution code"]],
                            "timeOfDay" = list("hour" = tod[1], "minute" = tod[2])),
              "measurements"=list("titleVarsLong" = titleVarsLong, 
                                  "titleVarsShort" = titleVarsShort, 
                                  "units" = units, 
                                  "matrices" = matrices,
                                  "method_refs" = method_refs,
                                  "addVarInfo" = addVarInfo, 
                                  "variables" = variables),
              "flags"=list("titleFlagsLong" = titleFlagsLong, 
                           "titleFlagsShort" = titleFlagsShort,
                           "numflags" = numflags),
              "addDataInfo" = addDataInfo, 
              "specialInfo" = specialInfo,
              "dataOrigin" = dataOrigin,
              "whereToFind" = whereToFind,
              "nVars" = nVars, 
              "nRowData" = nRowData)
  )
  
}
