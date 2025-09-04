using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
println(first(d.data, 3))
d["salinity"] = 2 * d["salinity"]
println(first(d.data, 3))

