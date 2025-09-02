using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
SA_ = SA(d)
CT_ = CT(d)
println(maximum(abs.(SA_ .- d.data.SA)))
println(maximum(abs.(CT_ .- d.data.CT)))
