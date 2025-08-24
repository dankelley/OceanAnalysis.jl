# Read a built-in CTD file, and plot some hydrographic diagrams
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "ctd.cnv")
ctd = read_ctd_cnv(filename)
p1 = plot_profile(ctd, "SA")
p2 = plot_profile(ctd, "CT")
p3 = plot_TS(ctd)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
savefig("cnv_example.png")
