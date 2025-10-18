"""
    coastline(symbol::Symbol=:world_fine)

Access a built-in [`Coastline`](@ref) dataset. The only valid choices for `name` are
`:global_coarse` and `:global_fine`.  These are handled by reading the built-in
datasets `data/coastline_coarse.csv.gz` and datasets
`data/coastline_fine.csv.gz`, respectively.

# Examples

```juliadoc
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

```juliadoc
# World view
using OceanAnalysis, Plots
dir = dirname(dirname(pathof(OceanAnalysis)))
file = joinpath(dir, "data", "coastline_coarse.csv.gz")
cl = coastline(file, 1)
plot_coastline(cl)
```
"""
function coastline(filename::String, header::Integer=1)
    !ismissing(filename) || error("must supply 'filename', the path to a CSV file")
    header > 0 || error("'header' must be a non-negative integer")
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
```juliadoc
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
    plot_coastline(coastline::Coastline;
        xlims=(-180., 180.), ylims=(-90., 90.),
        seriestype=:shape, color=:bisque3, linewidth=0.5, tickdirection=:out,
        kwargs...)

Plot a coastline with longitude and latitude axes (i.e. without a map projection).

The `aspect_ratio` of the plot is set as the reciprocal of the mean of the
`ylims` values, to preserve shapes near that spot.

# Arguments

- `coastline` the coastline, as constructed using [`coastline`](@ref) or (less commonly) [`Coastline`](@ref).

- `xlims` and `ylims` control the ranges of the longitude and latitude axes, respectively.

- `seriestype`, `color` and `linewidth` control the rendering of land regions. These values are passed to the base-level `plot` function; for details, see the documentation provided by the `Plots` package.
"""
function plot_coastline(coastline::Coastline;
    xlims=(-180., 180.), ylims=(-90., 90.),
    seriestype=:shape, color=:bisque3, linewidth=0.5, tickdirection=:out,
    kwargs...)
    aspect_ratio = 1.0 / cos(0.5 * (ylims[2] + ylims[1]) * pi / 180.0)
    #println("aspect_ratio: ", aspect_ratio)
    plot(coastline.data.longitude, coastline.data.latitude;
        xlims=xlims, ylims=ylims, aspect_ratio=aspect_ratio,
        seriestype=seriestype, color=color, linewidth=linewidth,
        legend=false, framestyle=:box, tickdirection=tickdirection, kwargs...)
end

"""
    plot_coastline!(coastline::Coastline;
        seriestype=:shape, color=:bisque3, linewidth::Real=0.5)

Add a coastline to an existing plot.

This shares several arguments with [`plot_coastline`](@ref), but not those
that could alter the geometry.  Note that the plot limits are inherited
from the existing plot, so `xlim` and `ylim` should not be supplied
in the `kwargs...` grouping.

# Arguments

- `coastline` the coastline, as constructed using [`coastline`](@ref) or, by more advanced users, using [`Coastline`](@ref).

# Keywords

- `seriestype`, `color` and `linewidth` control the rendering of land regions. These values are passed to the base-level `plot` function; for details, see the documentation provided by the `Plots` package.
"""
function plot_coastline!(coastline::Coastline;
    seriestype=:shape, color=:bisque3, linewidth=0.5, tickdirection=:out, kwargs...)
    plot!(coastline.data.longitude, coastline.data.latitude,
        xlims=xlims(), ylims=ylims(), # inherit from previous plot
        seriestype=seriestype, color=color, linewidth=linewidth, legend=false,
        tickdirection=tickdirection, kwargs...)
end

"""
    scale_bar(distance::Real=100.0, x=:left, y=:top;
        linewidth::Real=2.0, fontsize::Real=8)

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

```juliadoc
using OceanAnalysis, Plots
cl = coastline();
plot_coastline(cl, xlims=(-70, -60), ylims=(42, 48))
scale_bar(100.0)
```
"""
function scale_bar(distance::Real=100.0, x=:left, y=:top; linewidth::Real=3.0, fontsize::Real=9)
    distance > 0.0 || error("'distance' must be a positive number")
    xlim, ylim = xlims(), ylims() # from existing plot_coastline() diagram
    ymid = (ylim[1] + ylim[2]) / 2.0
    km_per_degree_lon = geod_distance(xlim[1] - 0.5, ymid, xlim[1] + 0.5, ymid)
    dx = (xlim[2] - xlim[1]) / 20 # FIXME: may need to adjust the divisor to look nice
    dy = (ylim[2] - ylim[1]) / 20
    if x == :left
        X = xlim[1] + dx .+ [0.0, distance / km_per_degree_lon]
    elseif x == :right
        X = xlim[2] - dx .- [0.0, distance / km_per_degree_lon]
    elseif isa(x, Number)
        #X = x + dx .+ [0.0, distance / km_per_degree_lon]
        X = x .+ [0.0, distance / km_per_degree_lon]
    else
        error("x must be :left, :right, or a number, but it is ", x)
    end
    #println("X: ", X)
    if y == :top
        y0 = ylim[2] - 1.5 * dy
    elseif y == :bottom
        y0 = ylim[1] + dy
    elseif isa(y, Number)
        y0 = y
    else
        error("y must be :top, :bottom, or a number, but it is ", y)
    end
    #println("y0: ", y0)
    Y = [y0, y0]
    #println("Y: ", Y)
    plot!(X, Y, color=:black, linewidth=linewidth)
    annotate!((X[1] + X[2]) / 2.0, Y[1] + 0.66 * dy,
        Plots.text("$(trunc(Int, distance)) km", fontsize))
end
