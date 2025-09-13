# Plot earth with the coarse dataset and Nova Scotia with the fine dataset
using OceanAnalysis, Plots
clc = coastline(:global_coarse);
clf = coastline(:global_fine);
# World view
p1 = plot(clc.data.longitude, clc.data.latitude,
    xlim=(-180, 180), ylim=(-90, 90),
    aspect_ratio=1.0,
    seriestype=:shape, color=:bisque3, legend=false, framestyle=:box)
# Nova Scotia view, with aspect_ratio set for the middle latitude
p2 = plot(clf.data.longitude, clf.data.latitude,
    xlim=(-68, -59), ylim=(42, 48),
    aspect_ratio=1.0 / cos(45.0 * pi / 180),
    seriestype=:shape, color=:bisque3, legend=false, framestyle=:box)
l = @layout [a{0.66w} b{0.33w}]
plot(p1, p2, layout=l)
savefig("maps.png")
