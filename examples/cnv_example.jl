# Read a built-in CTD file, and plot some standard diagrams
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "ctd.cnv")
ctd = read_ctd_cnv(filename, debug=1)
p1 = plot_profile(ctd, "SA", debug=1)
p2 = plot_profile(ctd, "CT", debug=1)
p3 = plot_TS(ctd, debug=1)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
savefig("cnv_example.png")
