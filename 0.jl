using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
SA = SA(d)
println(SA)
