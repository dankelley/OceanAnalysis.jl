using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc"
d = read_amsr(f, "SST");
longitude = d.metadata["longitude"];
latitude = d.metadata["latitude"];
SST = d.data
heatmap(longitude, latitude, SST, framestyle=:box, aspect_ratio=:equal,
    xlims=(0, 360), ylims=(-90, 90), dpi=300, size=(800, 400),
    title=f * ": SST", titlefontsize=9)
savefig("amsr.png")

