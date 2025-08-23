# Read a built-in CTD file, and plot a profile of Absolute Salinity
# %%
using OceanAnalysis, Plots, Measures
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "ctd.cnv")
ctd = readCtdCNV(filename);

# %%
p1 = plotProfile(ctd, "SA", debug=1)

# %%
p2 = plotProfile(ctd, "CT", debug=1)

# %%
p3 = plotTS(ctd, debug=1)

# %%
#plot(p1, p2, p3)#, layout=(1, 3))#, size=(800, 400), margin=0.25cm)

# %%
savefig("cnv_example.png")
