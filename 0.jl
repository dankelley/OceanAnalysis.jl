using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
SA_ = SA(d)
println(first(SA_, 10))
CT_ = CT(d)
println(first(CT_, 10))
