library(oce)
file <- "adp_rdi.000"
adp <- read.adp.rdi(file, debug=3)
str(adp[["metadata"]])
str(adp[["data"]])
