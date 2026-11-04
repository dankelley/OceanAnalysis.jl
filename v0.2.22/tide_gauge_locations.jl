using OceanAnalysis
using GLMakie # or CairoMakie
cl = coastline()
i = get_tide_gauge_index(:all); # requires internet access
ip = i[i.type .== "PERMANENT", :] # permanent stations

limits = (-67, -59, 43.3, 47.2)
fig = plot_coastline(cl, limits=limits, scalebar=true, fontsize=12,
    title="Tide gauges (circled and labelled for permanent stations)")
scatter!(i.longitude, i.latitude, markersize=8, marker=:circle, color=:red)
scatter!(ip.longitude, ip.latitude, markersize=14, marker=:circle, strokecolor=:blue, color=:transparent, strokewidth=2)
text!(ip.longitude, ip.latitude; text=ip.name, fontsize=14, color=:blue)
save("tide_gauge_locations.png", fig, px_per_unit=2)

# Tabulate permanent stations within 400km of Bedford Institute, sorted
# by distance to the Bedford Institute station.
range = 400.0
bi = i[i.name .== "Bedford Institute", :]
distance = geod_distance.(bi.longitude, bi.latitude, i.longitude, i.latitude)
i[:, :distance] = distance
look = (distance .< range) .& (i.type .== "PERMANENT")
ilook = i[look, :]
println(sort(ilook, :distance))

