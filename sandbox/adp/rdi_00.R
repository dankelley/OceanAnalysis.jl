library(oce)
file <- "adp_rdi.000"
adp <- read.adp.rdi(file, debug=3)
str(adp[["metadata"]])

# Some results (to check against julia code):
#    bytesPerEnsemble=1832
#    numberOfDataTypes=6
#    haveActualData=TRUE
#    head(dataOffset)=18 77 142 816 1154 1492
#
#    length(profileStart)=9 after checking for bad profiles)
#    heading[1:9]: 278.14, 277.31, ..., 277.47, 276.98
#    profileStart2[1:18]: 78, 79, ..., 14750, 14751
#    pitch[1:9]: 1.42, 1.24, ..., 1.16, 1.12
#    roll[1:9]: -2.39, -2.49, ..., -2.38, -2.35
#    will adjust the pitch as explained on page 14 of 'adcp coordinate transformation.pdf'
#    pitch, before correction[1:9]: 1.42, 1.24, ..., 1.16, 1.12
#    pitch, after correction[1:9]: 1.4212, 1.2412, ..., 1.1610, 1.1209
#    temperature[1:9]: 12.06, 12.06, ..., 12.10, 12.11
#    pressure[1:9]: -0.244, -0.224, ..., -0.238, -0.266
