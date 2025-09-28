# Bay of Fundy at approximately 1.6km resolution
using OceanAnalysis, Plots, TiffImages
topo_file = get_topography_file(-68, -63, 43, 46, resolution=1)
topo = read_topography(topo_file);
lon = topo.metadata["longitude"]
lat = topo.metadata["latitude"]
water_depth = -topo.data; # depth is the negative of height
water_depth[water_depth.<0.0] .= NaN; # trim land
heatmap(lon, lat, water_depth,
    xlims=extrema(lon), ylims=extrema(lat),
    aspect_ratio=1.0 / cos(0.5 * (lat[1] + lat[end]) * pi / 180.),
    framestyle=:box, dpi=300,
    tickdirection=:out, color=:deep, clim=(0, 400))
cl = coastline();
plot!(cl.data.longitude, cl.data.latitude,
    seriestype=:shape, color=:bisque3, legend=false, linewidth=0.5)
savefig("topography.png")
