library(oce)
# D6902967_095.nc cased problems until 'missing' was tested for in read_argo()
f <- "/Users/kelley/data/argo/D6902967_095.nc"
d <- read.oce(f)
summary(d)
d[["pressure"]][, 1]
