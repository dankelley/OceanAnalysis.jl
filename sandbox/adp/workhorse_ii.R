library(oce)
file <- "/Users/kelley/Downloads/rdi_whii600_sample.000"
adp <- read.adp.rdi(file, debug = 1)
png("workhorse_ii_R.png", units = "in", width = 7, height = 6, res = 300)
P <- function(item, ylab) {
    oce.plot.ts(adp[["time"]], item, type = "p", ylab = ylab)
}

if (!is.null(adp[["ISMmag"]])) {
    par(mfcol = c(3, 2))
    P(adp[["ISMmag"]][, 1], "mag x")
    P(adp[["ISMmag"]][, 2], "mag y")
    P(adp[["ISMmag"]][, 3], "mag z")
    P(adp[["ISMacc"]][, 1], "acc x")
    P(adp[["ISMacc"]][, 2], "acc y")
    P(adp[["ISMacc"]][, 3], "acc z")
} else {
    message("This file does not have ISM data")
}

if (!is.null(adp[["ambientSound"]])) {
    par(mfcol = c(2, 2))
    P(adp[["ambientSound"]][, 1], "ambient sound beam 1")
    P(adp[["ambientSound"]][, 2], "ambient sound beam 2")
    P(adp[["ambientSound"]][, 3], "ambient sound beam 3")
    P(adp[["ambientSound"]][, 4], "ambient sound beam 4")
} else {
    message("This file does not have ambientSound data")
}

print(adp[["v"]][1,,])
print(adp[["v"]][2,,])
print(adp[["v"]][3,,])
