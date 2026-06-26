"""
    coastline(symbol::Symbol=:world_fine)

Access a built-in [`Coastline`](@ref) dataset. The only valid choices for `name` are
`:global_coarse` and `:global_fine`.  These are handled by reading the built-in
datasets `data/coastline_coarse.csv.gz` and datasets
`data/coastline_fine.csv.gz`, respectively.

# Examples

```julia
# Nova Scotia
using OceanAnalysis, Plots
cl = coastline(:global_fine);
plot_coastline(cl, xlims=(-68, -58), ylims=(43, 48))
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

"""
    coastline(filename::String, header::Integer=0)

Create a [`Coastline`](@ref) object from a CSV file.

The file must have columns named `longitude` and `latitude`, with NaN values
indicating breaks separating islands, etc.

The work is done by passing `filename` and `header` to `CSV.read()`. The file
must have 1 or more header lines, the last of which must contain column names
`longitude` and `latitude`. NaN values will be taken to indicate breaks between
segments that trace continents, nations, etc.

# Examples

```julia
# World view
using OceanAnalysis, Plots
dir = dirname(dirname(pathof(OceanAnalysis)))
file = joinpath(dir, "data", "coastline_coarse.csv.gz")
cl = coastline(file, 1)
plot_coastline(cl)
```
"""
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

"""
    coastline(longitude::Union{AbstractVector,AbstractRange},
        latitude::Union{AbstractVector,AbstractRange})

Create a [`Coastline`](@ref) object from longitude and latitude values.

Use NaN values for both `longitude` and `latitude` to indicate breaks in the
coastline from continent to continent, nation to nation, etc.

# Examples
```julia
# Nova Scotia
using OceanAnalysis, CSV, Plots, DataFrames
dir = dirname(dirname(pathof(OceanAnalysis)));
file = joinpath(dir, "data", "coastline_fine.csv.gz");
data = CSV.read(file, DataFrame, header=1);
cl = coastline(data.longitude, data.latitude);
plot_coastline(cl, xlims=(-68, -58), ylims=(43, 48))
```
"""
function coastline(longitude::Union{AbstractVector,AbstractRange},
    latitude::Union{AbstractVector,AbstractRange})
    metadata = Dict()
    metadata["source"] = "(user-supplied vectors of longitude and latitude)"
    data = DataFrame(longitude=longitude, latitude=latitude)
    Coastline(metadata, data)
end

"""
    plot_coastline(coastline::Coastline; debug::Integer=0, kwargs...)

Plot a coastline with longitude and latitude axes (i.e. without a map projection).

The `aspect_ratio` of the plot is set as the reciprocal of the mean of the
`ylims` values, to preserve shapes near that spot.

# Arguments

- `coastline` a [`Coastline`](@ref) object, as constructed using [`coastline`](@ref) or [`Coastline`](@ref).

# Keywords

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

- `kwargs...` other arguments, passed to `plot`, e.g. `xlim` and `ylim` to control the plot view, `fillcolor` (*not* `color`) for the land colour, etc.

# Examples
```julia
using OceanAnalysis, Plots
# Default world view
plot_coastline(coastline())
# Nova Scotia view, with land coloured a light gray
plot_coastline(coastline(); fillcolor=:gray85, xlim=(-70.0, -55.0), ylim=(43.0, 48.0))
```
"""
function plot_coastline(coastline::Coastline; debug::Integer=0, kwargs...)
    oad(debug, "plot_coastline() START")
    longitude = coastline["longitude"]
    latitude = coastline["latitude"]
    if haskey(kwargs, :ylim)
        kw = (; kwargs...)
        mid_latitude = 0.5 * sum(kw[:ylim])
    else
        mid_latitude = 0.5 * sum(extrema(filter(!isnan, latitude)))
    end
    oad(debug, "  mid_latitude=$mid_latitude")
    aspect_ratio = 1.0 / cos(mid_latitude * pi / 180.0)
    oad(debug, "  aspect_ratio=$aspect_ratio")
    rval = plot(longitude, latitude;
        xlim=(-180.0, 180.0), ylim=(-90.0, 90.0),
        aspect_ratio=aspect_ratio, legend=false, seriestype=:shape,
        fillcolor=:bisque3, linecolor=:black, linewidth=0.5,
        framestyle=:box, tickdirection=:out,
        kwargs...)
    oad(debug, "END plot_coastline()")
    rval
end

"""
    plot_coastline!(coastline::Coastline; fillcolor=:bisque3, debug::Integer=0, kwargs...)

Add a coastline to an existing plot.

This shares several arguments with [`plot_coastline`](@ref), but not those
that could alter the geometry.  Note that the plot limits are inherited
from the existing plot, so `xlim` and `ylim` should not be supplied
in the `kwargs...` grouping.

# Arguments

- `coastline` a [`Coastline`](@ref) object, as constructed using [`coastline`](@ref) or [`Coastline`](@ref).

# Keywords

- `fillcolor` a color specification, with default being a light brown.

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

- `kwargs...` other arguments, passed to `plot`, e.g. `xlim` and `ylim` to control the plot view, `color` for the land colour, etc.
"""
function plot_coastline!(coastline::Coastline; fillcolor=:bisque3, debug::Integer=0, kwargs...)
    oad(debug, "plot_coastline!() START")
    oad(debug, "  kwargs...: $(kwargs...)")
    rval = plot!(coastline["longitude"], coastline["latitude"];
        xlims=xlims(), ylims=ylims(), # inherit from previous plot
        legend=false, seriestype=:shape,
        fillcolor=fillcolor, linecolor=:black, linewidth=0.5,
        kwargs...)
    oad(debug, "END plot_coastline!()")
    rval
end

"""
    scale_bar(distance::Real=100.0; x=:left, y=:top,
        linewidth::Real=3.0, fontsize::Real=8)

Add a horizontal scalebar to a plot made with [`plot_coastline`]@ref).

The length of the scalebar, in km, is given by `distance`, at a position
dictated by `x` and `y`. The value of `x` must be `:left`, `:right` or a number
(for longitude), and the value of `y` must be `:bottom`, `:top` or a number
(for latitude).  The default is to place the scale bar at the top-left.
If none of the corners are suitable, e.g. if the label covers important
parts of the plot, use numeric values for `x` and `y` as the longitude
and latitude of the beginning of the line indicating the scale. The width
of the line is given by `linewidth`, and the fontsize of the label
is given by `fontsize`.

# Examples

```julia
using OceanAnalysis, Plots
cl = coastline();
plot_coastline(cl, xlim=(-70, -60), ylim=(42, 48))
scale_bar(100.0)
```
"""
function scale_bar(distance::Real=100.0; x=:left, y=:top, linewidth::Real=3.0, fontsize::Real=8)
    distance > 0.0 || throw(ArgumentError("distance must be a positive number, but it is $distance"))
    xlim, ylim = xlims(), ylims() # need these to avoid changing view in the existing plot
    ymid = (ylim[1] + ylim[2]) / 2.0
    km_per_degree_lon = geod_distance(xlim[1] - 0.5, ymid, xlim[1] + 0.5, ymid)
    dx = (xlim[2] - xlim[1]) / 20 # FIXME: may need to adjust the divisor to look nice
    dy = (ylim[2] - ylim[1]) / 15
    if x == :left
        X = xlim[1] + dx .+ [0.0, distance / km_per_degree_lon]
    elseif x == :right
        X = xlim[2] - dx .- [0.0, distance / km_per_degree_lon]
    elseif isa(x, Number)
        X = x .+ [0.0, distance / km_per_degree_lon]
    else
        throw(ArgumentError("x must be :left, :right, or a number, but it is $(repr(x))"))
    end
    if y == :top
        y0 = ylim[2] - 1.5 * dy
    elseif y == :bottom
        y0 = ylim[1] + dy
    elseif isa(y, Number)
        y0 = y
    else
        throw(ArgumentError("y must be :top, :bottom, or a number, but it is $(repr(y))"))
    end
    Y = [y0, y0]
    plot!(X, Y, color=:black, linewidth=linewidth, label=false, xlim=xlim, ylim=ylim)
    annotate!((X[1] + X[2]) / 2.0, Y[1] + 0.66 * dy,
        Plots.text("$(trunc(Int, distance)) km", fontsize))
end

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

