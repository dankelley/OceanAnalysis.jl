# %% Read a built-in Argo file, and plot some hydrographic diagrams
using OceanAnalysis, Plots, Measures, Dates
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
a = read_argo(filename)
# %% Plot an overview of hydrographic properties
title = "$(Dates.format(a.metadata["time"], "yyyy-mm-dd")) at " *
        "$(round(a.metadata["latitude"],digits=3))N " *
        "$(round(a.metadata["longitude"],digits=3))E"
p1 = plot_profile(a, "CT", title=title, titlefontsize=9)
p2 = plot_profile(a, "SA")
p3 = plot_profile(a, "sigma0")
p4 = plot_TS(a)
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 800), margin=0.25cm,
    dpi=200)
savefig("argo_profile.png")
