using OceanAnalysis, Plots
filename = expanduser("~/data/nonna/NONNA10_4460N06360W.tiff")
n = read_nonna(filename);
heatmap(n["longitude"], n["latitude"], n.data, c=:turbo,
    size=(400, 400), dpi=300, framestyle=:box, tickdirection=:out)
savefig("nonna.png")
