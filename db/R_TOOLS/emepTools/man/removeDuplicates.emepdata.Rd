% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/removeDuplicates.emepdata.R
\name{removeDuplicates.emepdata}
\alias{removeDuplicates.emepdata}
\title{Remove duplicate variables from an EMEP data variable/list (emepdata) as
returned by read.emepFile and getEmptyEmepData.}
\format{R Code}
\usage{
removeDuplicates.emepdata(emepdata,
  removeList = findDuplicates.emepdata(emepdata))
}
\arguments{
\item{emepdata}{emepdata: an EMEP data file given out by read.emepFile}

\item{removeList}{integer array: (optional) an integer array containing
indices of variables which shoul be removed from emepdata; if not 
parsed, removedList is filled by the call of 
findDuplicates.emepdata(emepdata)}
}
\value{
\item{changes}{logical: FALSE if new_data equals
         emepdata and TRUE otherwise (= if variables were dropped)}
 \item{removeList}{integer array: the same integer array as returned
         by findDuplicates.emepdata(emepdata)}
 \item{new_data}{list(): list of the same format as that 
         given back by the read.emepFile but without duplicate 
         variables (titleVarsShort)}
}
\description{
The array indices of duplicate variables are identified by the function
findDuplicates.emepdata(emepdata).
}
\details{
WE HAVE TWO SIMILAR FUNCTIONS 'removeDuplicatesNamesOnly.emepdata' AND
variable name, THE SECOND ONE COMPARES short variables name, matrix and 
method_ref.

The function removeEntries.emepdata removes the entries.
}
\note{
If no duplicates are present, new_data equals emepdata and changes
   is FALSE
}
\author{
Daniel Neumann, Helmholtz-Zentrum Geesthacht
   \email{daniel.neumann@___.de}
}

