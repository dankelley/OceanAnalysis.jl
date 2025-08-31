library(oce)
f <- "/Users/kelley/Dropbox/oce-working-notes/cnv/S262-023-CTD.cnv"
d <- read.oce(f)
options(width=200)
head(as.data.frame(d@data))
tail(as.data.frame(d@data))
