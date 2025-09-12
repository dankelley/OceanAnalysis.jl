using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
ctd = read_argo(filename)
p1 = plot_profile(ctd, "CT")
p2 = plot_profile(ctd, "SA")
p3 = plot_profile(ctd, "sigma0")
p4 = plot_TS(ctd)
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 800), margin=0.25cm,
    dpi=200)
savefig("argo_profile.png")
