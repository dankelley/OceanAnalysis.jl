# %%
using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv")
SA = d["SA"]
println(first(d["salinity"] ./ SA, 5))

#println("ORIG longitude: ", d["longitude"])
#d["longitude"] = 99.99
#println("NEW longitude: ", d["longitude"])
#println(first(d.data, 2))
#S2 = 2 * d["salinity"]
#d["salinity"] = S2
#println(first(d.data, 2))
