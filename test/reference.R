library(oce)
f <- "../data/adp_rdi.000"
beam <- read.adp.rdi(f)
xyz <- beamToXyz(beam)
enu <- xyzToEnu(xyz)
cat("heading: ", paste(enu[["heading"]][1:3], collapse=" "), "\n")
cat("pitch: ", paste(enu[["pitch"]][1:3], collapse=" "), "\n")
cat("roll: ", paste(enu[["roll"]][1:3], collapse=" "), "\n")

cat("beam:\n")
beam[["v"]][1,1,]
beam[["v"]][1,2,]

cat("xyz:\n")
xyz[["v"]][1,1,]
xyz[["v"]][1,2,]

cat("enu:\n")
enu[["v"]][1,1,]
enu[["v"]][1,2,]
enu[["v"]][2,1,]
enu[["v"]][2,2,]
# Graphs hand-checked vs julia here
# png("reference.png", units="in", width=7, height=5, res=200)
# par(mfrow=c(3,1))
# oce.plot.ts(enu[["time"]], enu[["v"]][,1,1])
# oce.plot.ts(enu[["time"]], enu[["v"]][,1,2])
# oce.plot.ts(enu[["time"]], enu[["v"]][,1,3])
