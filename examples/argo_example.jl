# Read a built-in Argo file, and plot some hydrographic diagrams
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
ctd = read_argo(filename)
p1 = plot_profile(ctd, "SA")
p2 = plot_profile(ctd, "CT")
p3 = plot_TS(ctd)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
savefig("argo_example.png")
