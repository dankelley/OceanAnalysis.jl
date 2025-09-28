# North Atlantic Sea Surface Temperature
using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc"
d = read_amsr(f, "SST");
longitude = d.metadata["longitude"];
latitude = d.metadata["latitude"];
SST = d.data;
heatmap(longitude, latitude, SST, framestyle=:box,
    xlims=(290.0, 360.0), ylims=(20.0, 60.0),
    aspect_ratio=1.0 / cos(pi * 40.0 / 180.0),
    color=:turbo, size=(800, 550), dpi=300,
    title=f * ": SST", titlefontsize=9,
    clim=(0, 30))
cl = coastline(:global_fine);
plot!(cl.data.longitude .+ 360, cl.data.latitude,
    seriestype=:shape, color=:bisque3, linewidth=0.8,
    legend=false)
contour!(longitude, latitude, SST, levels=0.0:2.5:40.0, color=:black)
savefig("amsr.png")
