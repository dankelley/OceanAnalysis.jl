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

#<DELETE> """
#<DELETE>     coastline(filename::String, header::Integer=0)
#<DELETE> 
#<DELETE> Create a [`Coastline`](@ref) object from a CSV file.
#<DELETE> 
#<DELETE> The file must have columns named `longitude` and `latitude`, with NaN values
#<DELETE> indicating breaks separating islands, etc.
#<DELETE> 
#<DELETE> The work is done by passing `filename` and `header` to `CSV.read()`. The file
#<DELETE> must have 1 or more header lines, the last of which must contain column names
#<DELETE> `longitude` and `latitude`. NaN values will be taken to indicate breaks between
#<DELETE> segments that trace continents, nations, etc.
#<DELETE> 
#<DELETE> # Examples
#<DELETE> 
#<DELETE> ```julia
#<DELETE> # World view
#<DELETE> using OceanAnalysis, Plots
#<DELETE> dir = dirname(dirname(pathof(OceanAnalysis)))
#<DELETE> file = joinpath(dir, "data", "coastline_coarse.csv.gz")
#<DELETE> cl = coastline(file, 1)
#<DELETE> plot_coastline(cl)
#<DELETE> ```
#<DELETE> """
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

#<DELETE> """
#<DELETE>     coastline(longitude::Union{AbstractVector,AbstractRange},
#<DELETE>         latitude::Union{AbstractVector,AbstractRange})
#<DELETE> 
#<DELETE> Create a [`Coastline`](@ref) object from longitude and latitude values.
#<DELETE> 
#<DELETE> Use NaN values for both `longitude` and `latitude` to indicate breaks in the
#<DELETE> coastline from continent to continent, nation to nation, etc.
#<DELETE> 
#<DELETE> # Examples
#<DELETE> ```julia
#<DELETE> # Nova Scotia
#<DELETE> using OceanAnalysis, CSV, Plots, DataFrames
#<DELETE> dir = dirname(dirname(pathof(OceanAnalysis)));
#<DELETE> file = joinpath(dir, "data", "coastline_fine.csv.gz");
#<DELETE> data = CSV.read(file, DataFrame, header=1);
#<DELETE> cl = coastline(data.longitude, data.latitude);
#<DELETE> plot_coastline(cl, xlims=(-68, -58), ylims=(43, 48))
#<DELETE> ```
#<DELETE> """
function coastline(longitude::Union{AbstractVector,AbstractRange},
    latitude::Union{AbstractVector,AbstractRange})
    metadata = Dict()
    metadata["source"] = "(user-supplied vectors of longitude and latitude)"
    data = DataFrame(longitude=longitude, latitude=latitude)
    Coastline(metadata, data)
end
export coastline

"""
    plot_coastline(coastline::Coastline; debug::Integer=0, kwargs...)

Plot a coastline with longitude and latitude axes (i.e. without a map projection).

The `aspect_ratio` of the plot is set as the reciprocal of the mean of the
`ylims` values, to preserve shapes near that spot.

# Arguments

- `coastline` a [`Coastline`](@ref) object, as constructed using [`coastline`](@ref) or [`Coastline`](@ref).

# Keywords

- `fontsize` size of fonts used in the plot. This will be used for the `plot()`
  arguments `tickfontsize`, `guidefontsize` and `titlefontsize`; to alter any
  of these, specify them within `kwargs...`.

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

- `kwargs...` other arguments, passed to `plot`, e.g. `xlim` and `ylim` to
  control the plot view, `fillcolor` (*not* `color`) for the land colour, etc.

# Examples
```julia
using OceanAnalysis, Plots
# Default world view
plot_coastline(coastline())
# Nova Scotia view, with land coloured a light gray
plot_coastline(coastline(); fillcolor=:gray85, xlim=(-70.0, -55.0), ylim=(43.0, 48.0))
```
"""
function plot_coastline(coastline::Coastline; fontsize::Real=8.0, debug::Integer=0, kwargs...)
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
        tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize,
        kwargs...)
    oad(debug, "END plot_coastline()")
    rval
end
export plot_coastline


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
export plot_coastline!

"""
    scale_bar(distance::Real=100.0; x=:left, y=:top,
        linewidth::Real=1.8, fontsize::Real=8)

Add a horizontal scalebar to a plot made with [`plot_coastline`]@ref).

The length of the scalebar, in km, is given by `distance`, at a position
dictated by `x` and `y`. The value of `x` must be `:left`, `:right` or a number
(for longitude), and the value of `y` must be `:bottom`, `:top` or a number
(for latitude).  The default is to place the scale bar at the top-left.
If none of the corners are suitable, e.g. if the label covers important
parts of the plot, use numeric values for `x` and `y` as the longitude
and latitude of the beginning of the line indicating the scale.

With `style=:Ibeam` (the default), a rotated Ibeam shape is drawn, with 2/3 of
the indicated thickness. With `style=:line`, distance is represented by a
single line that is drawn at the indicated thickness. An error is reported if
any other `style` value is given.

In both cases, `fontsize` dictates the size of the label.

# Examples

```julia
using OceanAnalysis, Plots
cl = coastline();
plot_coastline(cl, xlim=(-70, -60), ylim=(42, 48))
scale_bar(100.0)
```
"""
function scale_bar(distance::Real=100.0; x=:left, y=:top, linewidth::Real=1.8, fontsize::Real=8,
    style=:Ibeam)
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
    if style == :Ibeam
        linewidth = 2.0 * linewidth / 3.0
        DY = (X[2] - X[1]) / 30
        X = [X[1], X[1], X[1], X[2], X[2], X[2]]
        Y = [Y[1] + DY, Y[1] - DY, Y[1], Y[2], Y[2] + DY, Y[2] - DY]
    elseif style != :line
        error("style $(repr(style)) not handled; try :line or :Ibeam")
    end
    plot!(X, Y, color=:black, linewidth=linewidth, label=false, xlim=xlim, ylim=ylim)
    annotate!((X[1] + X[end]) / 2.0, y0 + 2.0 * dy / 3.0,
        Plots.text("$(trunc(Int, distance)) km", fontsize))
end
export scale_bar


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

