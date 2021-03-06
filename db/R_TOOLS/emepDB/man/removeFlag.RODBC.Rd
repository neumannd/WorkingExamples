% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/removeFlag.RODBC.R
\name{removeFlag.RODBC}
\alias{removeFlag.RODBC}
\title{Removes a numflag from the EMEP database}
\format{R Code}
\usage{
removeFlag.RODBC(channel, numflag)
}
\arguments{
\item{channel}{RODBC: open RODBC database connection}

\item{numflag}{character: numflag of the flag to remove; is unambiguous;}
}
\value{
list(err_code, err_string) list(integer, character): err_code (0 if successful, 1 if not successfull)
}
\description{
Removes a numflag from the EMEP database
}
\author{
Daniel Neumann, Helmholtz-Zentrum Geesthacht
   \email{daniel.neumann@___.de}
}

