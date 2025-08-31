using OceanAnalysis, Dates
#file = "/Users/kelley/git/OceanAnalysis.jl/data/ctd.cnv"
file = "/Users/kelley/data/arctic/beaufort/2012/d201211_0056.cnv"
print(file)
d = read_ctd_cnv(file)
print(": ", d.metadata["time"], " @ ", d.metadata["latitude"], "N, ", d.metadata["longitude"], "E\n")
