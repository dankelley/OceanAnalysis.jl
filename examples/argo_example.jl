# Read a built-in Argo file, and plot some hydrographic diagrams
# %%
using OceanAnalysis, Plots, Measures
pkgdir = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
print(filename)
# %%
ctd = readArgo(filename, debug=1)
p1 = plotProfile(ctd, "SA", debug=1)
p2 = plotProfile(ctd, "CT", debug=1)
p3 = plotTS(ctd, debug=1)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
savefig("argo_example.png")
