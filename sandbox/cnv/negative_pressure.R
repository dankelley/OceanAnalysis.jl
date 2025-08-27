library(oce)
f <- "/Users/kelley/Dropbox/oce-working-notes/cnv/S262-023-CTD.cnv"
d <- read.oce(f)
p <- d[["pressure"]]
s0 <- d[["sigma0"]]
bad <- sum(p < 0)
par(mfrow = c(2, 1))
plot(p, s0, type = "l")
range(s0, na.rm=TRUE)
hist(p[p < 0])
mtext(sprintf(
    "Have %d negative pressures, or %.2f percent of values",
    bad, 100 * bad / length(p)
))
