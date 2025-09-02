using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
println(first(d.data, 3))
println(SA(d))


