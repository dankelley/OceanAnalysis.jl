# Read and plot a built-in CTD file
using OceanAnalysis, Measures, Plots, Printf
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
title = @sprintf("CTD observations at %.3fN and %.3fE",
    ctd["latitude"], ctd["longitude"])
plot_TS(ctd, ms=3, title=title, markerstrokewidth=0, color_by="pressure")
savefig("ctd_TS.png")
