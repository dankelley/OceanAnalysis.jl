# Some 'BR' floats that lack PSAL (detected by OceanAnalysis julia code)
# The first file used here is the one I found, randomly.  The other is
# another file starting with BR (not same float ID) that also lacks
# salinity.
library(oce)
files <- c("BR4902576_017.nc", "BR4902577_016.nc")
for (file in files) {
    if (file.exists(file)) {
        cat("File: ", file, "\n")
        d <- read.argo(file)
        cat(sprintf("Agency: %s, PI: %s\n", d@metadata$institution[1], d@metadata$PIName[1]))
        cat("Data: ", sort(names(d@data)), "\n")
        cat("\n")
    }
}
