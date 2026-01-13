library(oce)
file <- "~/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
# I got the next by using Julia on the file, although R would be fine for that too.
indices <- seq(5041, 13681, by = 360)
#message(adpRdiFileTrim(file, "adp_sample.000", indices = indices))
adpRdiFileTrim(file, indices = indices, debug=1)
