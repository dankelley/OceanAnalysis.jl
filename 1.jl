using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
println(first(d.data, 3))
S2 = 2 * d["salinity"]
d["salinity"] = S2
println(first(d.data, 3))

