using OceanAnalysis, Dates
#file = "/Users/kelley/git/OceanAnalysis.jl/data/ctd.cnv"
file = "/Users/kelley/data/arctic/beaufort/2012/d201211_0056.cnv"
file = "/Users/kelley/data/arctic/beaufort/2004/d200416_049.cnv"
println(file)
d = read_ctd_cnv(file)
println(": ", d.metadata["time"], " @ ", d.metadata["latitude"], "N, ", d.metadata["longitude"], "E\n")
