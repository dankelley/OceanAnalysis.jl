using OceanAnalysis, Dates, Plots
f = "~/git/oce/create_data/rsk/060130_20150904_1159.rsk"
longitude = -(56 + 26.232 / 60);
latitude = 73 + 13.727 / 60;
t_start = DateTime("2015-09-04T15:37:21")
t_end = DateTime("2015-09-04T15:44:40")
ctd = read_ctd_rsk(f, longitude=longitude, latitude=latitude);
# Focus on the downcast (determined by inspecting P=P(t) graph, in R/oce package)
downcast = t_start .< ctd.data.time .< t_end
ctd.data = ctd.data[downcast, :];
# Plot some useful things
Sp = plot_profile(ctd, which="salinity", dpi=200)
Tp = plot_profile(ctd, which="temperature", dpi=200)
TS = plot_TS(ctd, dpi=200)
#tp = plot(ctd.data.time, ctd.data.pressure, dpi=200, col=:red)
cl = coastline()
distance_to_land = geod_distance.(longitude, latitude, cl.data.longitude, cl.data.latitude)
distance_to_nearest_land = minimum(x for x in distance_to_land if !isnan(x))
println(distance_to_nearest_land)
S = 5.0 * distance_to_nearest_land / 111 # deg lat
a = 1.0 / cos(latitude * pi / 180)
m = plot_coastline(cl, xlims=longitude .+ (-a * S, a * S), ylims=latitude .+ (-S, S); debug=1)
scatter!(m, [longitude], [latitude], label=false, color=:red)
plot(Sp, Tp, TS, m, layout=(2, 2))
savefig("rsk_01.png")
