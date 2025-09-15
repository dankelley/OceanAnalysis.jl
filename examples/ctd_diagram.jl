# %% Read a built-in CTD file
using OceanAnalysis, Plots, Measures, Dates
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "ctd.cnv")
ctd = read_ctd_cnv(filename)
# %% Plot some diagrams that are often useful in analysis
title = "$(Dates.format(ctd.metadata["time"], "yyyy-mm-dd")) at " *
        "$(round(ctd.metadata["latitude"],digits=3))N " *
        "$(round(ctd.metadata["longitude"],digits=3))E"
p1 = plot_profile(ctd, "CT", title=title, titlefontsize=9)
p2 = plot_profile(ctd, "SA")
p3 = plot_profile(ctd, "sigma0")
p4 = plot_TS(ctd)
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 800), margin=0.25cm,
    dpi=200)
savefig("ctd_diagram.png")
