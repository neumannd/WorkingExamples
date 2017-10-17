#' ssemis_start
#' 
#' Is used for calling ssemis_main*.R scripts. These scripts can be started
#' directly as well. This script simplifies the process when several sea
#' salt emission calculations are started in a loop.
#' 
#' @author Daniel Neumann
#' @date 2015-Nov-06
#' @version 4.0.1

# example call
# Rscript ssemis_start.R --args GRID_NAME=CD24 FROM=2008002 TO=2008003 MODE=1 AERO=5 CMAQ=5.0 SURF=FALSE


# Load libraries and external functions ----
source('ssemis_funs.R')


# programme ----
myArgs = ssemis_read_args(commandArgs(trailingOnly = TRUE))

if ('sssf'%in%tolower(myArgs$args.valid.names)) {
  iSSSF = which(myArgs$args.valid.names == 'sssf')
  sssf.name = myArgs$args.valid.list[['sssf']]
  sssf.args = myArgs$args.valid.flat[-iSSSF]
} else {
  mtext = paste('ssemis_start', 'The parsed arguments should contain an "sssf=XYZ".', sep = ': ')
  stop(mtext)
}

if (tolower(sssf.name)%in%c('go03', 'go', 'gong')) {sssf.name = 'gong'
} else if (tolower(sssf.name)%in%c('sp13', 'sp', 'spada')) { sssf.name = 'spada'
} else if (tolower(sssf.name)%in%c('ov13', 'ov', 'ovadnevaite')) { sssf.name = 'ovadnevaite'
} else {
  mtext = paste('ssemis_start:', 'The source function', sssf.name, 'does not exist or is not implemented', sep = '')
  stop(mtext)
}
                                                                   
sssf.script = paste(paste('ssemis_main', sssf.name, paste('v', ssemis_start_version, sep = ''), sep = '_'), 'R', sep = '.')

system(paste('Rscript', sssf.script, '--args', paste(sssf.args, collapse = ' '), sep = ' '))
