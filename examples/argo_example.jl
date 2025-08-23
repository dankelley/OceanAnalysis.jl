# Read a built-in CTD file, and plot a profile of Absolute Salinity
using OceanAnalysis, Plots, Measures
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "D4902911_095.nc")
ctd = readArgo(filename, debug=2)
p1 = plotProfile(ctd, "SA", debug=1)
p2 = plotProfile(ctd, "CT", debug=1)
p3 = plotTS(ctd, debug=1)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
savefig("argo_example.png")
