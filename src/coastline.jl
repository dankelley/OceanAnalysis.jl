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

For examples, see [`plot_coastline`](@ref).
"""
function coastline(name::Symbol=:global_fine)
    #println("coastline(name) BEGIN")
    if name == :global_fine
        rval = coastline(joinpath(pkgdir(OceanAnalysis), "data", "coastline_fine.csv.gz"), 1)
        rval.metadata["name"] = name
    elseif name == :global_coarse
        rval = coastline(joinpath(pkgdir(OceanAnalysis), "data", "coastline_coarse.csv.gz"), 1)
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


#<maybe code later but check other .jl file> """
#<maybe code later but check other .jl file>     station_map(longitude, latitude; scale::Real=5.0, debug::Integer=0, kwargs...)
#<maybe code later but check other .jl file> 
#<maybe code later but check other .jl file>     station_map!(fig_pos, longitude, latitude; scale::Real=5.0, debug::Integer=0, kwargs...)
#<maybe code later but check other .jl file> 
#<maybe code later but check other .jl file> Using [`plot_coastline`](@ref), draw a map that shows the location of a station
#<maybe code later but check other .jl file> (or stations) specified by `longitude` and `latitude`, each of which may be a
#<maybe code later but check other .jl file> single number or a vector of numbers (with longitude in the -180 to +180
#<maybe code later but check other .jl file> convention). The map span is computed automatically by computing
#<maybe code later but check other .jl file> the distance between the centroid of the stations and the nearest point of land
#<maybe code later but check other .jl file> and also computing the span across the stations.  The maximum of these
#<maybe code later but check other .jl file> two distances is multiplied by `scale`, and from this the x and y
#<maybe code later but check other .jl file> limits of the plot are set.  Altering the value of `scale` is thus
#<maybe code later but check other .jl file> the way a user can control the view. The station locations
#<maybe code later but check other .jl file> are drawn by calling `scatter`, to which
#<maybe code later but check other .jl file> the `kwargs...` elements are passed directly; the example
#<maybe code later but check other .jl file> shows how to use this fact to alter the station symbols.
#<maybe code later but check other .jl file> 
#<maybe code later but check other .jl file> Map projections are not offered by `station_map`; to get such views, consider
#<maybe code later but check other .jl file> using the `GMT` package.
#<maybe code later but check other .jl file> 
#<maybe code later but check other .jl file> # Examples
#<maybe code later but check other .jl file> 
#<maybe code later but check other .jl file> ```julia
#<maybe code later but check other .jl file> using OceanAnalysis
#<maybe code later but check other .jl file> using GLMakie # or CairoMakie
#<maybe code later but check other .jl file> station_map(-56.33, 45.90, debug=1)
#<maybe code later but check other .jl file> ```
#<maybe code later but check other .jl file> """
#<maybe code later but check other .jl file> function station_map(longitude, latitude; scale::Real=5.0, debug::Integer=0, kwargs...)
#<maybe code later but check other .jl file>     oad(debug, "station_map() BEGIN")
#<maybe code later but check other .jl file>     fig = Makie.Figure()
#<maybe code later but check other .jl file>     ax, plot = station_map!(fig[1, 1], longitude, latitude;
#<maybe code later but check other .jl file>         scale=scale, debug=increment_debug(debug), kwargs...)
#<maybe code later but check other .jl file>     oad(debug, "END station_map()")
#<maybe code later but check other .jl file>     return Makie.FigureAxisPlot(fig, ax, plot.main)
#<maybe code later but check other .jl file> end
#<maybe code later but check other .jl file> export station_map
#<maybe code later but check other .jl file> 
#<maybe code later but check other .jl file> function station_map!(fig_pos, longitude, latitude;
#<maybe code later but check other .jl file>     scale::Real=5.0, debug::Integer=0, kwargs...)
#<maybe code later but check other .jl file>     oad(debug, "station_map() START")
#<maybe code later but check other .jl file>     oad(debug, "  kwargs...: $(kwargs...)")
#<maybe code later but check other .jl file>     length(longitude) == length(latitude) || throw(ArgumentError("longitude and latitude are of unequal lengths ($(length(longitude)) and $(length(latitude)))"))
#<maybe code later but check other .jl file>     cl = coastline()
#<maybe code later but check other .jl file>     lon0 = mean(longitude)
#<maybe code later but check other .jl file>     lat0 = mean(latitude)
#<maybe code later but check other .jl file>     distance_to_land = geod_distance.(lon0, lat0, cl.data.longitude, cl.data.latitude)
#<maybe code later but check other .jl file>     distance_to_nearest_land = minimum(x for x in distance_to_land if !isnan(x))
#<maybe code later but check other .jl file>     oad(debug, "  distance_to_nearest_land: ", distance_to_nearest_land, " km")
#<maybe code later but check other .jl file>     distance_across_stations = maximum(geod_distance.(lon0, lat0, longitude, latitude))
#<maybe code later but check other .jl file>     oad(debug, "  distance_across_stations: ", distance_across_stations, " km")
#<maybe code later but check other .jl file>     # Next approximates 1 degree of latitude as 111 km
#<maybe code later but check other .jl file>     dlat = scale * maximum([distance_to_nearest_land, distance_across_stations]) / 111.0
#<maybe code later but check other .jl file>     oad(debug, "  dlat: ", dlat)
#<maybe code later but check other .jl file>     aspect_ratio = 1.0 / cos(lat0 * pi / 180) # aspect ratio
#<maybe code later but check other .jl file>     oad(debug, "  aspect_ratio: ", aspect_ratio)
#<maybe code later but check other .jl file>     ax = Makie.Axis(fig_pos[1, 1])
#<maybe code later but check other .jl file>     cl = coastline()
#<maybe code later but check other .jl file>     main = plot_coastline!(fig_pos[1, 1], cl; debug=increment_debug(debug))
#<maybe code later but check other .jl file>     Makie.scatter!([longitude], [latitude])
#<maybe code later but check other .jl file>     oad(debug, "END station_map()")
#<maybe code later but check other .jl file>     return ax, (main=main.land,)
#<maybe code later but check other .jl file> end
#<maybe code later but check other .jl file> export station_map!

