using OceanAnalysis, Plots, Measures, GibbsSeaWater

filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "ctd.cnv")
ctd = read_ctd_cnv(filename)

#plot_TS(ctd, sigma0_levels=10)
#plot_TS(ctd, sigma0_levels=0, debug=1)
plot_TS(ctd, spiciness0_levels=[], debug=1)
savefig("TS_test_j.png")
