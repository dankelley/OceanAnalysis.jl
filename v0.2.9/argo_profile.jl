# Read and plot a built-in Argo file
using OceanAnalysis, Dates, Measures, Plots, Printf
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
argo = read_argo(filename)
ctd = as_ctd(argo)
p1 = plot_profile(ctd; which="CT");
p2 = plot_profile(ctd; which="SA");
p3 = plot_profile(ctd; which="sigma0");
p4 = plot_TS(ctd);
title = @sprintf("CTD observations at %.3fN and %.3fE, on %s",
    ctd.metadata["latitude"], ctd.metadata["longitude"],
    Dates.format(ctd.metadata["time"], "yyyy-mm-dd"))
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 600), margin=0.25cm,
    dpi=200, plot_title=title, plot_titlefontsize=9)
savefig("argo_profile.png")

