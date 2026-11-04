# Read and plot a built-in CTD file
using OceanAnalysis
using Printf
using GLMakie # or CairoMakie
filename = joinpath(pkgdir(OceanAnalysis), "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
title = @sprintf("CTD observations at %.3fN and %.3fE",
    ctd["latitude"], ctd["longitude"])
fig = plot_TS(ctd, title=title)
save("ctd_TS.png", fig, px_per_unit=2)
