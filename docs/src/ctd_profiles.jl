# Read and plot a built-in CTD file
using OceanAnalysis, Dates, Measures, Plots, Printf
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
p1 = plot_profile(ctd; which="CT");
p2 = plot_profile(ctd; which="SA");
p3 = plot_profile(ctd; which="sigma0");
title = @sprintf("CTD observations at %.3fN and %.3fE on %s",
    ctd["latitude"], ctd["longitude"], ctd["time"])
plot(p1, p2, p3, layout=(1, 3), size=(800, 600), margin=0.25cm,
    dpi=200, plot_title=title, plot_titlefontsize=11)
savefig("ctd_profiles.png")
