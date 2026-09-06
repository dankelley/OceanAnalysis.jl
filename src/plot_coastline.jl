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

