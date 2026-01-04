library(oce)
file <- "adp_rdi.000"
adp <- read.adp.rdi(file, debug = 3)
str(adp[["metadata"]])
str(adp[["data"]])
cat("time\n")
print(adp[["time"]])
cat("soundSpeed\n")
print(adp[["soundSpeed"]])
cat("heading\n")
print(adp[["heading"]])
cat("pitch\n")
print(adp[["pitch"]])
cat("roll\n")
print(adp[["roll"]])

print(names(adp[["data"]]))

for (ensemble in 1:2) {
    cat("ensemble = ", ensemble, "\n")
    for (cell in 1:2) {
        cat("  cell ", cell, "\n")
        cat("    v ", paste(adp[["v"]][ensemble, cell, 1:4], collapse = " "), "\n")
        cat("    q ", paste(adp[["q"]][ensemble, cell, 1:4], collapse = " "), "\n")
        cat("    a ", paste(adp[["a"]][ensemble, cell, 1:4], collapse = " "), "\n")
        cat("    g ", paste(adp[["g"]][ensemble, cell, 1:4], collapse = " "), "\n")
    }
    cat("\n")
}
cm = colormap(zlim=c(-0.2,0.2), col=oceColorsTwo)
png("rdi_00.png")
imagep(t(-adp[["v"]][1,,]), colormap=cm)
dev.off()
