using OceanAnalysis, Dates, Plots
import Statistics: mean

function oad(debug, msg)
    if debug > 0
        println(msg)
    end
end

"""
   station_map(longitude, latitude;
       scale::Real=5.0, markersize=2, color=:red, debug::Int64=0)

Using [`plot_coastline`](@ref), draw a map that shows the location of a station
(or stations), with some nearby coastline. The geographical region
is determined by finding the nearest distance to land and multiplying
its span by the `scale` argument. Adjusting `markersize` and `color` will
alter the look of the station point(s).
"""
function station_map(longitude, latitude; scale::Real=5.0, markersize=2, color=:red, debug::Int64=0)
    oad(debug, "station_map() START")
    cl = coastline()
    lon0 = mean(longitude)
    lat0 = mean(latitude)
    distance_to_land = geod_distance.(lon0, lat0, cl.data.longitude, cl.data.latitude)
    distance_to_nearest_land = minimum(x for x in distance_to_land if !isnan(x))
    oad(debug, "    distance to nearest land is ", distance_to_nearest_land, "km")
    S = scale * distance_to_nearest_land / 111.0 # 1 lat deg ~ 111 km distance
    ar = 1.0 / cos(lat0 * pi / 180) # aspect ratio
    oad(debug, "    aspect ratio is ", ar, "km")
    map = plot_coastline(cl,
        xlims=lon0 .+ (-ar * S, ar * S), ylims=lat0 .+ (-S, S);
        debug=increment_debug(debug))
    scatter!(map, [longitude], [latitude], label=false, markersize=markersize, color=color)
    oad(debug, "END station_map()")
    map
end

f = "~/git/oce/create_data/rsk/060130_20150904_1159.rsk"
longitude = -(56 + 26.232 / 60);
latitude = 73 + 13.727 / 60;
t_start = DateTime("2015-09-04T15:37:21")
t_end = DateTime("2015-09-04T15:44:40")
ctd = read_ctd_rsk(f, longitude=longitude, latitude=latitude);
# Focus on the downcast (determined by inspecting P=P(t) graph, in R/oce package)
downcast = t_start .< ctd.data.time .< t_end;
ctd.data = ctd.data[downcast, :];
# Plot some useful things
Sp = plot_profile(ctd, which="salinity", dpi=200);
Tp = plot_profile(ctd, which="temperature", dpi=200);
TS = plot_TS(ctd, dpi=200);
#tp = plot(ctd.data.time, ctd.data.pressure, dpi=200, col=:red)

#? cl = coastline()
#? distance_to_land = geod_distance.(longitude, latitude, cl.data.longitude, cl.data.latitude)
#? distance_to_nearest_land = minimum(x for x in distance_to_land if !isnan(x))
#? println(distance_to_nearest_land)
#? S = 5.0 * distance_to_nearest_land / 111 # deg lat
#? a = 1.0 / cos(latitude * pi / 180)
#? m = plot_coastline(cl, xlims=longitude .+ (-a * S, a * S), ylims=latitude .+ (-S, S); debug=1)
#? scatter!(m, [longitude], [latitude], label=false, color=:red)

m = station_map(longitude, latitude, markersize=10, color=:turquoise);
plot(Sp, Tp, TS, m, layout=(2, 2))
#savefig("rsk_01.png")
