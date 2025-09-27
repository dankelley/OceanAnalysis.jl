using OceanAnalysis, Dates, Plots
f = get_amsr_file(Date("2025-07-01"), destdir="~/data/amsr")
d = read_amsr(f, "SST");
longitude = d.metadata["longitude"];
latitude = d.metadata["latitude"];
SST = d.data;
xlims = (300, 360)
ylims = (40, 60)
heatmap(longitude, latitude, SST, framestyle=:box,
    aspect_ratio=1 / cos(pi * 0.5 * (ylims[1] + ylims[2]) / 180),
    xlims=xlims, ylims=ylims, dpi=300, size=(800, 400),
    title=f * ": SST", titlefontsize=9, color=:turbo)
contour!(longitude, latitude, SST, levels=5:35:1, color=:black)
cl = coastline(:global_fine)
plot!(cl.data.longitude .+ 360, cl.data.latitude, seriestype=:shape, color=:bisque3, legend=false)
savefig("emma.png")
