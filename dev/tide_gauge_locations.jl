using OceanAnalysis
using GLMakie # or CairoMakie
cl = coastline()
i = get_tide_gauge_index(:all); # requires internet access

limits = (-67, -59, 43.3, 47.2)
fig = plot_coastline(cl, limits=limits, scalebar=true, fontsize=12,
    title="Tide gauges (red for permanent stations)")
scatter!(i.longitude, i.latitude, color=:blue, markersize=8)
look = i.type .== "PERMANENT"
scatter!(i.longitude[look], i.latitude[look], color=:red, markersize=18)

save("tide_gauge_locations.png", fig, px_per_unit=5)

