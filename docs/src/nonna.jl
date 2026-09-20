using OceanAnalysis
using GLMakie # or CairoMakie
filename = expanduser("~/data/nonna/NONNA10_4460N06360W.tiff")
if isfile(filename)
    n = read_nonna(filename)
    fig = heatmap(n["longitude"], n["latitude"], permutedims(n.data), colormap=:turbo,
        axis=(aspect=DataAspect(),))
    save("nonna.png", fig)
end
