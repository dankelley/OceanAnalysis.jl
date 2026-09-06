"""
    coastline(symbol::Symbol=:world_fine)
    coastline(filename::String, header::Integer=0)
    coastline(longitude::Union{AbstractVector,AbstractRange}, latitude::Union{AbstractVector,AbstractRange})

Specify a coastline, in one of three possible ways.

In the first method, use a built-in [`Coastline`](@ref) dataset (in the first form) or read a
CSV file holding coastline `longitude` and `latitude` columns. In the first case,
the only valid choices for `name` are `:global_coarse` and `:global_fine`.
These are handled by reading the built-in datasets
`data/coastline_coarse.csv.gz` and datasets `data/coastline_fine.csv.gz`,
respectively.

In the second method provide `filename` and `header` to `CSV.read()`. This
file must contain columns name `longitude` and `latitude`, and must use
NaN values to indicate breaks in the coastline.

And, in the third method, the arguments specify `longitude` and `latitude`
directly, again with NaN values to indicate breaks in the coastline.

# Examples

```julia
using OceanAnalysis, Plots
# Method 1
cl = coastline(:global_fine);
plot_coastline(cl, xlims=(-68, -58), ylims=(43, 48))
# Method 2
dir = dirname(dirname(pathof(OceanAnalysis)))
file = joinpath(dir, "data", "coastline_coarse.csv.gz")
cl = coastline(file, 1)
# Method 3
dir = dirname(dirname(pathof(OceanAnalysis)));
file = joinpath(dir, "data", "coastline_fine.csv.gz");
data = CSV.read(file, DataFrame, header=1);
cl = coastline(data.longitude, data.latitude);
```
"""
function coastline(name::Symbol=:global_fine)
    #println("coastline(name) BEGIN")
    dir = dirname(dirname(pathof(OceanAnalysis)))
    if name == :global_fine
        rval = coastline(joinpath(dir, "data", "coastline_fine.csv.gz"), 1)
        rval.metadata["name"] = name
    elseif name == :global_coarse
        rval = coastline(joinpath(dir, "data", "coastline_coarse.csv.gz"), 1)
        rval.metadata["name"] = name
    else
        error("    the only choices for 'name' are :global_coarse and :global_fine, but :", name, " was given")
    end
    rval
end
export coastline

function coastline(filename::String, header::Integer=1)
    isfile(filename) || throw(ArgumentError("there is no file named $filename"))
    header > 0 || throw(ArgumentError("header must be a non-negative integer, but it is $header"))
    metadata = Dict()
    metadata["filename"] = expanduser(filename)
    data = CSV.read(filename, DataFrame, header=header)
    column_names = names(data)
    "longitude" in column_names || error("no 'longitude' column in CSV file; found ", column_names)
    "latitude" in column_names || error("no 'latitude' column in CSV file; found ", column_names)
    Coastline(metadata, data)
end
export coastline

function coastline(longitude::Union{AbstractVector,AbstractRange},
    latitude::Union{AbstractVector,AbstractRange})
    metadata = Dict()
    metadata["source"] = "(user-supplied vectors of longitude and latitude)"
    data = DataFrame(longitude=longitude, latitude=latitude)
    Coastline(metadata, data)
end
export coastline


"""
    station_map(longitude, latitude; scale::Real=5.0, debug::Integer=0, kwargs...)

Using [`plot_coastline`](@ref), draw a map that shows the location of a station
(or stations) specified by `longitude` and `latitude`, each of which may be a
single number or a vector of numbers (with longitude in the -180 to +180
convention). The map span is computed automatically by computing
the distance between the centroid of the stations and the nearest point of land
and also computing the span across the stations.  The maximum of these
two distances is multiplied by `scale`, and from this the x and y
limits of the plot are set.  Altering the value of `scale` is thus
the way a user can control the view. The station locations
are drawn by calling `scatter` from the `Plots` package, to which
the `kwargs...` elements are passed directly; the example
shows how to use this fact to alter the station symbols.

Map projections are not offered by `station_map`; to get such views, consider
using the `GMT` package.

# Examples

```julia
using OceanAnalysis, Plots
# Red circle marks a station south of due east of Fort Louisbourg
# and due south of Saint Pierre and Miquelon.
p1 = station_map(-56.33, 45.90)
# The same, but with different aesthetics
p2 = station_map(-56.33, 45.90;
    markercolor=:gray85, markershape=:diamond, markersize=6)
plot(p1, p2)
```
"""
function station_map(longitude, latitude; scale::Real=5.0, debug::Integer=0, kwargs...)
    oad(debug, "station_map() START")
    oad(debug, "  kwargs...: $(kwargs...)")
    length(longitude) == length(latitude) || throw(ArgumentError("longitude and latitude are of unequal lengths ($(length(longitude)) and $(length(latitude)))"))
    cl = coastline()
    lon0 = mean(longitude)
    lat0 = mean(latitude)
    distance_to_land = geod_distance.(lon0, lat0, cl.data.longitude, cl.data.latitude)
    distance_to_nearest_land = minimum(x for x in distance_to_land if !isnan(x))
    oad(debug, "  distance_to_nearest_land: ", distance_to_nearest_land, " km")
    distance_across_stations = maximum(geod_distance.(lon0, lat0, longitude, latitude))
    oad(debug, "  distance_across_stations: ", distance_across_stations, " km")
    # Next approximates 1 degree of latitude as 111 km
    dlat = scale * maximum([distance_to_nearest_land, distance_across_stations]) / 111.0
    oad(debug, "  dlat: ", dlat)
    aspect_ratio = 1.0 / cos(lat0 * pi / 180) # aspect ratio
    oad(debug, "  aspect_ratio: ", aspect_ratio)
    map = plot_coastline(cl;
        xlim=lon0 .+ aspect_ratio .* (-dlat, dlat), ylim=lat0 .+ (-dlat, dlat),
        aspect_ratio=aspect_ratio,
        color=:black,
        debug=increment_debug(debug), kwargs...)
    #println("kwargs...:", kwargs...)
    scatter!(map, [longitude], [latitude], label=false; kwargs...)
    oad(debug, "END station_map()")
    map
end
export station_map

