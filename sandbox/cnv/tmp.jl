# %%
using OceanAnalysis, Dates
file = "/Users/kelley/git/OceanAnalysis.jl/data/ctd.cnv"
file = "/Users/kelley/data/arctic/beaufort/2012/d201211_0056.cnv"
println("file", file)
d = read_ctd_cnv(file, debug=1)
println(d.metadata)
