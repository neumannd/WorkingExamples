library('emepTools')

setwd('/home/neumannd/TMP/emep_tools/package/emepPackagesTesting/emep_data')


cat('\n~~~~~~~~~~~~\n READ FILES INTO R \n~~~~~~~~~~~~\n')
cat('SHOULD WORK: read file into R with read.emepFile \n')
myData1 = read.emepFile('TT/TT00001R.good.nas')
cat('SHOULD WORK: read file into R with read.emepFile \n')
myData2 = read.emepFile('TT/TT00009R.neutral.nas')
myData3 = read.emepFile('TT/TT00005.neutral.nas')
myData4 = read.emepFile('TT/TT00010R.neutral.nas')


cat('\n~~~~~~~~~~~~\n GENERATE EMPTY EMEP DATA \n~~~~~~~~~~~~\n')
cat('\nSHOULD WORK: generate empty EMEP data with getEmptyEmepData \n')
myDataEmpty = getEmptyEmepData()


cat('\n~~~~~~~~~~~~\n CONVERT DATA FORMAT FOR CTMEVAL \n~~~~~~~~~~~~\n')
cat("\nSHOULD WORK: convert EMEP data into format for the 'ctmeval' package with convert2ctmeval.emepdata \n")
myDataCtmeval = convert2ctmeval.emepdata(myData1, calc_mean = FALSE)
cat("\nAchtung: Der Output ist noch kein echtes observationts Objekt. \n")


