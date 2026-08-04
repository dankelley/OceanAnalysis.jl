using OceanAnalysis, Plots
i = get_tide_gauge_index(:all);
scatter(i.longitude, i.latitude,
    aspect_ratio=1.0 / cos(48.0 * pi / 180),
    framestyle=:box, tickdirection=:out, label=false, ms=0,
    xlim=(-67, -59), ylim=(43.3, 47.2))
plot_coastline!(coastline(:global_fine), fillcolor=:gray95)
scatter!(i.longitude, i.latitude, color=:blue, ms=3,
    markerstrokewidth=0.2)
look = i.type .== "PERMANENT"
scatter!(i.longitude[look], i.latitude[look],
    color=:red, ms=4, markerstrokewidth=0.2)
savefig("tide_gauge_stations.png")

