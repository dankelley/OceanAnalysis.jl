library(oce)
f <- "adp_rdi_2615_trimmed.000"
a <- read.oce(f)
A <- beamToXyzAdp(a)
png("01_beam_R.png", unit="in", width=7, height=5, res=300)
plot(a)
dev.off()
png("01_xyz_R.png", unit="in", width=7, height=5, res=300)
plot(A)
dev.off()

