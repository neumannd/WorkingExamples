# This programme converts SST and Salinity from the BSH format into netCDF 
# format.
#
# @author Daniel Neumann
# @version 9.0
# @date 2015/02/05
# 

print('This programme converts SST and Salinity from the BSH format into netCDF format.')

## environment ----
setwd('~/storage/neumannd/data/bsh')
library('ncdf4')


## names and parameters ----
# directories
inDir='/h/bsh/bsh_v4/bsh_v4_2012_01'   # input directory
outDir='~/storage/neumannd/data/bsh/infiles/BSHcmod4'
supDir='~/storage/neumannd/data/tools/convertBSH/bshcmod'

# files
supportFile = 'noku_tiefen_komp'
inFilePrefix = 't'
outFilePrefix = ''

# grids
grids = c('no', 'ku')
iGrid = 'no'

# set dimensions
nxNO=414
nyNO=347
nzNO=11
n3NO=248214
n2NO=37188

nxKU=630
nyKU=387
nzKU=8
n3KU=544751
n2KU=124011

ncols = nxNO
nrows = nyNO
nlays = nzNO
n3d = n3NO
n2d = n2NO

## read in and formate support data ----
print('Start reading grid definition file:')
print(paste(supDir, supportFile, sep="/"))
# open coordinate file
fileHandle <- file(         
  paste(supDir, supportFile, sep="/"),  # open file fDir/fName
  open="rt"                             # open as read-only
)

# read in coordinate and other data
#  *Coords = coordinates ; 20 values per line
#  *Depth = bathymetry information ; 15 values per line
#  *Unknown = ??? ; 50 values per line
noCoords = scan(fileHandle, nlines = 79012) # 79012 lines => 79011*20 + 18 = 1580238
noDepth = scan(fileHandle, nlines = 98040 - 79012) # 19029 lines =>  1028*15 + 10 = 285430
noUnknow = scan(fileHandle, nlines = 98784 - 98040) # 744 lines => 744 * 50 + 39 = 37239
kuCoords = scan(fileHandle, nlines = 196308 - 98784)
kuDepth = scan(fileHandle, nlines = 240893 - 196308)
kuUnknow = scan(fileHandle, nlines = 243374 - 240893)

# close file
close(fileHandle)

# redim arrays
dim(noCoords) = c(nyNO,nxNO,nzNO)
# reorderCoords = aperm(noCoords, c(2,1,3))
# image(reorderCoords[,347:1,1]>0)
# sum(reorderCoords[,347:1,1]>0)
dim(kuCoords) = c(nyKU,nxKU,nzKU)

if(max(noCoords[,,1]) != n2NO ) warning('inconsistent surface layer indices in NO grid')
if(max(noCoords) != n3NO ) warning('inconsistent indices in 3d NO grid')
if(max(kuCoords[,,1]) != n2KU ) warning('inconsistent surface layer indices in KU grid')
if(max(kuCoords) != n3KU ) warning('inconsistent indices in 3d KU grid')


print('Starting for-loop to iterate dates')
  for (iTime in 2008001:2008366) {
## read in and format real data ----
  print(paste('Starting for date ',formatC(iTime, format = 'd', width = 7), sep = ''))
  # time conversion
  ## julian to normal
  # jDate=2012006
  jDate=iTime
  iYear=floor(jDate/1000)
  jDay=jDate%%1000
  cDate=as.POSIXct((jDay-1)*60*60*24, tz = "UTC", origin = paste(iYear,"-01-01 00:00:00 UTC", sep = ""))
  strYear = format(cDate, format = "%Y")
  strMonth = format(cDate, format = "%m")
  strDay = format(cDate, format = "%d")
  
  ## normal to julian
  # cDate = as.POSIXct("2012-04-19 UTC")
  # strYear = format(cDate, format = "%Y")
  # iYear = as.integer(strYear)
  # strMonth = format(cDate, format = "%m")
  # strDay = format(cDate, format = "%d")
  # jDate = as.integer( iYear * 1000 + 
  #                       round(
  #                         julian( cDate, 
  #                                 origin = as.Date(paste(strYear, "-01-01", sep="")), 
  #                                 tz = "UTC")
  #                         ) + 1 )
  
  
  if ( strYear %in% c('2008', '2009', '2010', '2011', '2012') ) {
    inDir=paste('~/h/bsh/bsh_v4/bsh_v4', strYear, strMonth, sep = '_') # input directory
    # e.g. '/h/bsh/bsh_v4/bsh_v4_2012_01'
  } else if ( strYear == '2013' ) {
    inDir=paste('~/storage/neumannd/data/bsh/infiles', '2013', sep = '/') # input directory
  }
  # otherwise: keep value set in the beginning
  
  
  
  # iterate grids (NO and KU)
  # for (iGrid in grids[2]) {
  for (iGrid in grids) {
    if ( tolower(iGrid) == 'no' ) {
      ncols=nxNO
      nrows=nyNO
      nlays=nzNO
      n3d=n3NO
      n2d=n2NO
      myCoords = noCoords
    } else if ( tolower(iGrid) == 'ku' ) {
      ncols=nxKU
      nrows=nyKU
      nlays=nzKU
      n3d=n3KU
      n2d=n2KU
      myCoords = kuCoords
    } else {
      stop('BAD GRID NAME. GRID DOES NOT EXIST')
    }
  
    # open file and read header
    inFile = paste(inFilePrefix, strYear, strMonth, strDay, '00.', tolower(iGrid), '.gz', sep = '')
    print('  Opening file:')
    print(paste(inDir, inFile, sep = "/"))
    fileHandle = gzfile(paste(inDir, inFile, sep = "/"),
                      open="rt")
    myHead = scan(fileHandle, what = character(), nlines = 1)
    nRecs = as.integer(myHead[2])  # number of records
    print('  Reading data')
    
    # create arrays for data
    outSST = array(0.0, dim = c(ncols, nrows, nRecs))
    outSal = array(0.0, dim = c(ncols, nrows, nRecs))
    outTime = array(0.0, dim = c(2, 2, nRecs))
    
    
    # read and format data
    # for (iRec in 1:1) {
    for (iRec in 1:nRecs) {
      # read single line with date and time of following data set
      myTimes = scan(fileHandle, what = character(), nlines = 1)
      tmpDate = strsplit(myTimes[1], ".", fixed = TRUE)[[1]]
      tmpTime = strsplit(myTimes[2], ":", fixed = TRUE)[[1]]
      # tmpTime[3] is days since 1st Jan 1900
      
      # test if we have opened a bad file
      if (tmpDate[1] != strYear || tmpDate[2] != strMonth || tmpDate[3] != strDay) {
        if (myTimes[2] != "00:00:00") {
          warning(paste('Date in record ', 
                        formatC(iRec, format='d'),
                        ' of file ',
                        inFile,
                        ' has a bad date.', 
                        sep = '')
                  )
        }
      }
      
      # write time into array to write it later into file
      outTime[1, ,iRec] = jDate
      outTime[2, ,iRec] = as.integer(tmpTime[1])*10^4 + as.integer(tmpTime[2])*10^2 + as.integer(tmpTime[3])
      
      
      # read new data set
      #  NO: bis ...
      #  KU: nach 10896 Zeilen ist temp zu Ende und nach weiteren 10896 is sal
      #       zu Ende. Wenn man den ersten Datensatz (iRec == 1) sucht, started
      #       temp in Zeile 3 und endet in Zeile 10898. Sal started in Zeile 
      #       10898 und endet in Zeile 21793. ES IST KEIN ZEILENUMBRUCH ZWISCHEN
      #       DEN temp UND sal DATENSAETZEN!!! Es folgen 124012 0en (Nullen) 
      #       (bis Zeile 24273). 124011 ist die Anzahl an surface layer Daten-
      #       saetzen. Vermutlich koennte man hier noch was anderes unterbringen.
      # short version
      #  (2x 3d-dataset + 1x 2d-dataset + each (3x) one NA value ) 50 values per line
      #  NO: 10673 lines = (2 * 248214 + 1 * 37188 + 3) / 50 rounded up
      #  KU: 24271 lines = (2 * 544751 + 1 * 124011 + 3) / 50 rounded up
      myData = scan(fileHandle, nlines = ceiling((n3d + n3d + n2d + 3)/50))
      
      # split raw data
      # There are max(noCoords) [== n3NO = n3d] temperature and max(noCoords) salinity 
      # values plus each on "NA" value. All values are contained in myData:
      #  myData[                1]:                     NA value of temperature
      #  myData[                2:(max(noCoords)+1)]:   values of temperature
      #  myData[(max(noCoords)+2)]:                     NA value of salinity
      #  myData[(max(noCoords)+3):(2*max(noCoords)+2)]: values of salinity
      rawT = myData[1:(n3d+1)]
      rawS = myData[(n3d+2):(2*n3d+2)]
            
      rawT[1] = NA
      rawS[1] = NA
      
      ## format 
      for (iRow in 1:nrows) {
        for (iCol in 1:ncols) {
          outSST[iCol, nrows - iRow + 1, iRec] = rawT[myCoords[iRow, iCol, 1]+1]/100
          outSal[iCol, nrows - iRow + 1, iRec] = rawS[myCoords[iRow, iCol, 1]+1]/100
        }
      }
    
    }
    print('  Closing file.')
    close(fileHandle)
    
    print('  Clearing variables from read-in process.')
    rm(myData)  # to reduce amount of data in the memory 
    rm(rawT)
    rm(rawS)
    
## write output netcdf file ----

    print('  Start writing file:')
    outFile = paste('bsh_t_latlon_', 
                    formatC(jDate, format='d', width=7), 
                    '_', tolower(iGrid), '.nc', 
                    sep = "")
    print(paste(outDir, outFile, sep = "/"))    

    nLon=ncols
    nLat=nrows
    if (tolower(iGrid) == 'no') {
      dLon=0.08333333333333 # = 5'
      dLat=0.05  # = 3'
      minLon = -4.041666666667 # -4° 02' 30''
      maxLon = minLon + dLon * (nLon - 1)
      maxLat = 65.875 # 65° 52' 30''
      minLat = maxLat - dLat * (nLat - 1)
    } else if ( tolower(iGrid) == 'ku' ) {
      dLon=0.01388888889 # = 50''
      dLat=0.008333333 # = 0.5'
      minLon = 6.17361111111111 # 6° 10' 25''
      maxLon = minLon + dLon * (nLon - 1)
      maxLat = 56.44583333333333333 # 56° 26' 45''
      minLat = maxLat - dLat * (nLat - 1)
    } else {
      stop('BAD GRID NAME. GRID DOES NOT EXIST')
    }
    
    outSeconds = as.double(cDate) - as.double(as.POSIXct('1900-01-01 00:00:00 UTC', tz = "UTC")) + (1:24)*60*60
    
    # define dimensions
    dimCOL = ncdim_def('lon', units = 'degrees east', vals = seq(from=minLon, to=maxLon, by=dLon) , create_dimvar = TRUE)
    dimROW = ncdim_def('lat', units = 'degrees north', vals = seq(from=minLat, to=maxLat, by=dLat), create_dimvar = TRUE)
    dimTIME = ncdim_def('time', units = 'seconds since 1900-01-01 00:00:00', vals = outSeconds, unlim = TRUE, create_dimvar = TRUE)
    dimDT = ncdim_def('DATE-TIME', units = '', vals = 1:2, create_dimvar = FALSE)
    dimVAR = ncdim_def('VAR', units = '', vals = 1:2, create_dimvar = FALSE)
    
    varTFLAG = ncvar_def( name = 'TFLAG', units = '<YYYYDDD,HHMMSS>',
                          dim = list(dimDT, dimVAR, dimTIME),
                          longname = 'TFLAG           ')
    
    varSST = ncvar_def( name = 'SST', units = 'degree celsius', 
               dim = list(dimCOL, dimROW, dimTIME),
               longname = 'sea_surface_temperature', missval = NaN)
    
    
    varSAL = ncvar_def( name = 'SALINITY', units = 'g/kg', 
               dim = list(dimCOL, dimROW, dimTIME),
               longname = 'salinity', missval = NaN)
    
    ncId <- nc_create(paste(outDir, outFile, sep = "/"),
                      list(varTFLAG, varSST, varSAL))
    
    ncvar_put(ncId, 'TFLAG', outTime)
    ncvar_put(ncId, 'SST', outSST)
    ncvar_put(ncId, 'SALINITY', outSal)
    
    ncatt_put(ncId, 'SST', 'coordinates', 'lon lat')
    ncatt_put(ncId, 'SALINITY', 'coordinates', 'lon lat')
    
    ncatt_put(ncId, 'TFLAG', 'var_desc', 'Timestep-valid flags:  (1) YYYYDDD or (2) HHMMSS                                ')
    ncatt_put(ncId, 'SST', 'var_desc', 'sea surface temperature')
    ncatt_put(ncId, 'SALINITY', 'var_desc', 'salinity of the sea surface water')
    
    ncatt_put(ncId, 'lon', 'long_name', 'longitude')
    ncatt_put(ncId, 'lon', 'standard_name', 'longitude')
    ncatt_put(ncId, 'lat', 'long_name', 'latitude')
    ncatt_put(ncId, 'lat', 'standard_name', 'latitude')
    
    #' add global attributes
    ncatt_put(ncId, varid=0, attname='FTYPE', 
              attval=as.integer(1), prec='int')
    ncatt_put(ncId, varid=0, attname='CDATE', 
              attval=as.integer(format(Sys.time(), format="%Y")) * 10^3 + 1 + julian(Sys.Date(), origin = as.Date(paste(format(Sys.time(), format="%Y"), "-01-01", sep=""))), 
              prec='int')
    ncatt_put(ncId, varid=0, attname='CTIME', 
              attval=as.integer(format(Sys.time(), format="%H%M%S")), 
              prec='int')
    ncatt_put(ncId, varid=0, attname='WDATE', 
              attval=as.integer(format(Sys.time(), format="%Y")) * 10^3 + 1 + julian(Sys.Date(), origin = as.Date(paste(format(Sys.time(), format="%Y"), "-01-01", sep=""))), 
              prec='int')
    ncatt_put(ncId, varid=0, attname='WTIME', 
              attval=as.integer(format(Sys.time(), format="%H%M%S")), 
              prec='int')
    
    ncatt_put(ncId, varid=0, attname='SDATE', attval=formatC(jDate, format='d'), prec='int')
    ncatt_put(ncId, varid=0, attname='STIME', attval=as.integer(0), prec='int') # TODO: Wann starten: 0 oder 1 uhr?
    ncatt_put(ncId, varid=0, attname='TSTEP', attval=as.integer(100), prec='int') # TODO
    
    ncatt_put(ncId, varid=0, attname='NTHIK', attval=as.integer(nRecs), prec='int')
    ncatt_put(ncId, varid=0, attname='NCOLS', attval=as.integer(-1), prec='int')
    ncatt_put(ncId, varid=0, attname='NROWS', attval=as.integer(-1), prec='int')
    ncatt_put(ncId, varid=0, attname='NLAYS', attval=as.integer(1), prec='int')
    
    ncatt_put(ncId, varid=0, attname='NVARS', attval=as.integer(2), prec='int')
    
    ncatt_put(ncId, varid=0, attname='GDTYP', attval=as.integer(-1), prec='int')
    
    ncatt_put(ncId, varid=0, attname='GDNAM', attval = 'TODO', prec='text')
    ncatt_put(ncId, varid=0, attname='UPNAM', attval = '', prec='text') # TODO
    ncatt_put(ncId, varid=0, attname='VAR-LIST', 
              attval = 'SST             SALINITY        ', prec='text')
    ncatt_put(ncId, varid=0, attname='FILEDESC', attval="salinity and sea surface temperature from the BSHcmod v4", prec='text')
    ncatt_put(ncId, varid=0, attname='HISTORY', 
              attval = "Created at HZG KBT. Contact: Daniel Neumann, daniel.neumann@hzg.de", 
              prec='text')
    
    print('  Closing output file')
    nc_close(ncId)
    
    print('  Clearing variables from writing process.')
    rm(outSST)  # to reduce amount of data in the memory 
    rm(outSal)
    rm(outTime)
    rm(ncId)

    print('  Calling garbage collector.')
    gc() # run garbage collector

  }
}
