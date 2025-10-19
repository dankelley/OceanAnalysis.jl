# Read and plot a built-in Argo file
using OceanAnalysis, Plots, Measures, Dates
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
a = read_argo(filename)
p1 = plot_profile(a, which="CT");
p2 = plot_profile(a, which="SA");
p3 = plot_profile(a, which="sigma0");
p4 = plot_TS(a);
title = "CTD observations at " *
        "$(round(a.metadata["latitude"],digits=3))N and " *
        "$(round(a.metadata["longitude"],digits=3))E" *
        " on $(Dates.format(a.metadata["time"], "yyyy-mm-dd"))"
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 600), margin=0.25cm,
    dpi=200, plot_title=title, plot_titlefontsize=11)
savefig("argo_profile.png")
