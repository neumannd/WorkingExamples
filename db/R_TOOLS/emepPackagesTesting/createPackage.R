## load libraries
library('roxygen2')
library('devtools')

## go into package top directory
setwd('/home/neumannd/TMP/emep_tools/package')

## create new packages
# create('emepTools')
# create('emepDB')

## fill the packages and modify DESCRIPTION file
# ...
# ...

## create documentation
setwd('~/TMP/emep_tools/package/emepTools/')
document()
setwd('~/TMP/emep_tools/package/emepDB/')
document()

## leave package directory
setwd('~/TMP/emep_tools/package')

## install the new packages
install('emepTools')
install('emepDB')

