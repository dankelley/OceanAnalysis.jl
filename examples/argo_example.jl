# Read a built-in Argo file, and plot some hydrographic diagrams
# %%
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
# %%
ctd = read_argo(filename, debug=2)
# %%
p1 = plot_profile(ctd, "SA", debug=1)
p2 = plot_profile(ctd, "CT", debug=1)
p3 = plot_TS(ctd, debug=1)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
savefig("argo_example.png")
