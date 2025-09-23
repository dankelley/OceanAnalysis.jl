# Bay of Fundy at approximately 1.6km resolution
using OceanAnalysis, Plots, TiffImages
topo_file = get_topography_file(-68, -63, 43, 46, resolution=1)
topo = read_topography(topo_file);
water_depth = -topo.data; # depth is the negative of height
water_depth[water_depth .< 0.0] .= NaN; # trim land
heatmap(topo.metadata["longitude"], topo.metadata["latitude"], water_depth,
        aspect_ratio=1.0/cos(44.5*pi/180.),
        framestyle=:box, dpi=300,
        xlims=extrema(topo.metadata["longitude"]),
        ylims=extrema(topo.metadata["latitude"]),
        color=:deep, clim=(0, 400))
cl = coastline();
plot!(cl.data.longitude, cl.data.latitude, color=:black, legend=false, linewidth=0.5)
savefig("topography.png")
