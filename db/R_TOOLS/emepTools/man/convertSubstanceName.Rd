% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convertSubstanceName.R
\name{convertSubstanceName}
\alias{convertSubstanceName}
\title{Convert the name of a variable into a convenient form.}
\format{R Code}
\usage{
convertSubstanceName(titleIn, conv2which = "")
}
\arguments{
\item{titleIn}{; character ; a variable name which should be converted into 
another format}

\item{conv2which}{; character ; (optional) defines in which format titleIn 
should be converted; It can be choosen from "long", "short", "shortEMEP",
"shortDB" and "" whereas "" and "short" are equal to "shortDB". If
set to another value a warning is thrown and titleOut=titleIn is 
returned. The default value of conv2which is "shortDB".}
}
\value{
titleOut ; character ; the variable name in the format defined by 
   conv2which; by default
}
\description{
shortEMEP: sum formular of the substance as used in the EMEP ASCII
           export files; standard sum formular with - and +; no spaces
shortDB:   sum formular of the substance without - and +; sometimes
           shorter than the EMEP short format such as susp_part_mat
           instead of susp_part_matter; sometimes more information as
           wspd10m instead of wspd; no spaces;
long:      long name of the substance as used in the variable definitions
           in the EMEP ASCII export file (header, line 13 and following) 
           (often IUPAC convention); no spaces;
}
\note{
If titleIn is unknown then titleOut = titleIn.
}
\author{
Daniel Neumann, Helmholtz-Zentrum Geesthacht
   \email{daniel.neumann@___.de}
}

