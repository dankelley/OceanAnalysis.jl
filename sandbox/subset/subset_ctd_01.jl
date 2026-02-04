using OceanAnalysis, Plots

f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
a = read_argo(f)

ctd = as_ctd(a);
a = plot_TS(ctd);

ctd_top = subset_ctd(ctd, ctd["pressure"] .< 300; debug=1)
b = plot_TS(ctd, title="same as top-left?")
ctd = subset_ctd!(ctd, ctd["pressure"] .< 300; debug=1)
c = plot_TS(ctd_top)
d = plot_TS(ctd, title="same as bottom-left?")
plot(a, b, c, d, layout=(2, 2), size=(700, 500))
savefig("subset_ctd_01.png")
