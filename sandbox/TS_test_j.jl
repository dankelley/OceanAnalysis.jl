using OceanAnalysis, Plots, Measures, GibbsSeaWater

filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "ctd.cnv")
ctd = read_ctd_cnv(filename)

#plot_TS(ctd, sigma0_levels=10)
plot_TS(ctd)
savefig("TS_test_j.png")
