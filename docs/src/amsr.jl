using OceanAnalysis, CairoMakie
file = get_amsr()
sst = read_amsr(file, "SST");
fig = plot_amsr(sst; xlims=(275.0, 350.0),
    ylims=(20.0, 65.0), colorrange=(-2.0, 30.0),
    title="Sea-surface Temperature [°C] with 1-km isobath")
# Add 1-km isobath. Note the transposition of the data (for Makie)
# and the redrawing, to handle the fact that AMSR has 0<=lon<=360
# whereas topograph has -180<=lon<=180.
ax = fig[1, 1]
tf = get_topography()
t = read_topography(tf);
contour!(ax, t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
contour!(ax, 360.0 .+ t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
save("amsr.png", fig)
