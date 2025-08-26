library(oce)

d <- read.oce("../data/ctd.cnv")
png("contour_test_R.png", height = 400, width = 800, pointsize = 15, res=100)
par(mfrow = c(1, 3))
plotProfile(d, xtype = "SA")
plotProfile(d, xtype = "CT")
plotTS(d)
