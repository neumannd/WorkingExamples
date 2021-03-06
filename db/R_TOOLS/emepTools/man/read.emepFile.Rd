% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read.emepFile.R
\name{read.emepFile}
\alias{read.emepFile}
\title{Import a text file in the EBAS v1.1 format (EMEP data file) into R}
\format{R Code}
\usage{
read.emepFile(file)
}
\arguments{
\item{file}{character: path of the EMEP text file to import (path = dir/file)}
}
\value{
emep_file list(): Contains all information from the file in
   a list with sub lists. Please look to the end of this function
   for the structure of the list.
}
\description{
Opens and reads an EMEP ASCII file. The data is separated from the
header. Both sets of information are put into returned list. The time
of measurements in the output list is formated as the time in CMAQ
result files.
}
\details{
\strong{emep file structure}

EMEP measurement files are written as ASCII text files in a modified 
NASA-Ames 1001 format. A nice description can be found at
http://www.eusaar.net/files/data/nasaames/index.html . See also
http://ebas-submit.nilu.no/ for some other informations.

Currently all text files which are exported from the EBAS system have the 
same structure. At first come several lines overhead. After that the 
headlines for different columns of data are given in one lines. In the next
line the data starts. Each lines of data contains measurements at one date.

The different columns contain start- and end-date of measurements, the 
measured values and sometimes flags. This flags indicate the quality of the
measurement. See http://www.nilu.no/projects/ccc/flags/index.html for a list
of flags.

Each data column has a short and a long name. In the file header a list of
all measured variables is given in long names. The actual column headlines
are short names.

File Structure: 
  line              1: (INT)rowData INT
                        line in which headlines of columns of data are; 
                        some integer
                                          search in code for BLOCK01
  lines       2 to  4: dataOrigin
                      some information on the source of the data (which 
                        agency etc.)
                                          search in code for BLOCK02
  line              5: whereToFind
                      in which databases is this data?
                                          search in code for BLOCK03
  line              6: INT INT
                      two integers of unknown function
                                          search in code for BLOCK04
  line              7: YYYY MM DD  YYYY MM DD
                      Two dates are in this line. The dates are saved as
                        Strings and Integers
                      The first data is the data, when the first observation
                        was performed.
                      The second data is the revision data of the instrument
                        (I think so)
                      twoDatesString as String (YYYY MM DD)
                      twoDatesInt as Integer (YYYYDDD) DDD = day of year
                                          search in code for BLOCK05
  line              8: length of time step, dt
                      Daily data: dt = 1
                      Weekly data: dt = 7
                      Hourly data:
                              dt = 1 (unit hours)
                              dt = 0.041667 (unit days)
                                          search in code for BLOCK06
  line              9: STR
                      explanation to the line before
                                          search in code for BLOCK07
  line             10: nCols-1
                      Number of lines with information to data colums. One
                       line for each colums with data. For the first column
                       there is no description. Therefore this number is the
                       "number of columns" - 1
                                          search in code for BLOCK08
  line             11: FLOATs
                      format of data values
                                          search in code for BLOCK09
  line             12: FLOATs
                      max (?) of data values
                                          search in code for BLOCK10
  line 13 to 12+nCols: STR
                      Description of the data columns later. Each description
                       is a comma separated list of values:
                       1.           column name (long version)
                       2.           unit
                       3., 4., ...  further information
                      Further information is partly processed #' NEW_v09_001
                                          search in code for BLOCK11
  line       13+nCols: 0
                      This may be also != 0. But I never had this case.
                       Therefore I ignore it here. #' NEW_v09_001
                                          search in code for BLOCK12
  line       14+nCols: nAddDataInfo+1
                      "Current line" + "this value" = "line number with
                       column headlines"
                      In the following lines in between is additional
                       information for this data set. It has the format
                       "[DATA TYPE]: ADD DATA".
                                          search in code for BLOCK13
  line     posRowData: titlesShort
                      titles of data columns; nCols strings separated by
                       each one space (" ");
                      (posRowData = 14 + nCols + nAddDataInfo)
                                          search in code for BLOCK14
  line   posRowData+1: data[1,]
  line   posRowData+2: data[2,]
  line   posRowData+i: data[i,]
                      The data is read in as strings because some values
                       may cause problems when they are represented as
                       floating point numbers.

end of file structure
}
\note{
This is the heart of this package.
}
\author{
Daniel Neumann, Helmholtz-Zentrum Geesthacht
   \email{daniel.neumann@___.de}
}

