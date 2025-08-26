using OceanAnalysis
f = "ctd.cnv"
d = read_ctd_cnv(f)
println(d.metadata["longitude"])
println(d.metadata["latitude"])
