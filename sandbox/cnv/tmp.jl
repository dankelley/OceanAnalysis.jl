# %%
using OceanAnalysis, Dates
file = "/Users/kelley/git/OceanAnalysis.jl/data/ctd.cnv"
println("file", file)
file_short_name = replace.(file, r".*/" => "")
println("file_short_name", file_short_name)
d = read_ctd_cnv(file, debug=1)
println(d.metadata)
