library(oce)
f <- "/Users/kelley/Dropbox/oce-working-notes/cnv/dsbe19plus_01906749_2014_09_01_0002.cnv"
d <- read.oce(f)
summary(d)
png("a_r.png")
plotTS(d, eos="unesco")

