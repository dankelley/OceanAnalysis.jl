
library(oce)
f <- "~/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
system.time(d <- read.adp.rdi(f))


