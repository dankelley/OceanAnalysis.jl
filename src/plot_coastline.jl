"""
    draw_coastline_polygons!(ax, longitude, latitude; color=:bisque3, debug=0)

Helper for [`plot_amsr`](@ref). Coastline data are stored as `longitude` and
`latitude` vectors with `NaN` separating individual land-mass rings (this is
the convention Plots' `seriestype=:shape` relied on). Makie has no direct
equivalent, so this splits the vectors on `NaN` and fills each ring
separately with `poly!`.
"""
function draw_coastline_polygons!(ax, longitude, latitude; linewidth=0.5,
    color=:bisque3, debug=0)
    oad(debug, "draw_coastline_polygons!() START")
    oad(debug, "    color=:$color")
    polygons = Polygon{2,Float32}[]
    start = 1
    n = length(longitude)
    oad(debug, "    assembling polygons")
    for i in 1:n+1
        if i == n + 1 || isnan(longitude[i]) || isnan(latitude[i])
            if i - start >= 3
                ring = Point2f.(longitude[start:i-1], latitude[start:i-1])
                push!(polygons, Polygon(ring))
            end
            start = i + 1
        end
    end
    oad(debug, "    plotting the assembled polygons")
    if !isempty(polygons)
        if color == :white
            poly!(ax, polygons, strokewidth=linewidth, strokecolor=:black)
        else
            poly!(ax, polygons, color=color, strokewidth=linewidth, strokecolor=:black)
        end
    end
    oad(debug, "END draw_coastline_polygons!()")
end
# not exported


"""
    plot_coastline(coastline::Coastline; debug::Integer=0, kwargs...)

Plot a coastline with longitude and latitude axes (i.e. without a map projection).

The `aspect_ratio` of the plot is set as the reciprocal of the mean of the
`ylims` values, to preserve shapes near that spot.

# Arguments

- `coastline` a [`Coastline`](@ref) object, as constructed using
  [`coastline`](@ref) or [`Coastline`](@ref).

# Keywords

- `fontsize` size of fonts used in the plot. This will be used for the `plot()`
  arguments `tickfontsize`, `guidefontsize` and `titlefontsize`; to alter any
  of these, specify them within `kwargs...`.

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

- `kwargs...` other arguments, passed to `plot`, e.g. `xlim` and `ylim` to
  control the plot view, `color` (*not* `color`) for the land colour, etc.

# Examples
```julia
using OceanAnalysis, CairoMakie

# 1. Coarse-resolution world view
plot_coastline(coastline(:global_coarse))

# 2. Nova Scotia view, with land coloured a light gray,
# plus some labels
plot_coastline(coastline(:global_fine), color=:gray85,
    xlabel="Longitude", ylabel="Latitude", title="Study Region",
    limits=(-70.0, -55.0, 43.0, 48.0))
```
"""
function plot_coastline(coastline::Coastline; limits=(-180.0, 180, -90.0, 90.0),
    fontsize::Real=8.0, debug::Integer=0, kwargs...)
    oad(debug, "plot_coastline() START")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    linewidth = pop!(kwargs_dict, :linewidth, 1.0)
    oad(debug, "    linewidth=$linewidth")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "    title=$title")
    xlabel = pop!(kwargs_dict, :xlabel, "")
    oad(debug, "    xlabel=$xlabel")
    ylabel = pop!(kwargs_dict, :ylabel, "")
    oad(debug, "    ylabel=$ylabel")
    color = pop!(kwargs_dict, :color, "bisque3")
    oad(debug, "    color=$color")
    mid_latitude = 0.5 * (limits[3] + limits[4])
    oad(debug, "    computed mid_latitude=$mid_latitude")
    aspect_ratio = 1.0 / cos(mid_latitude * pi / 180.0)
    oad(debug, "    computed aspect_ratio=$aspect_ratio")
    box_aspect = (limits[2] - limits[1]) / ((limits[4] - limits[3]) * aspect_ratio)
    oad(debug, "    computed box_aspect=$box_aspect")
    fig = Figure()
    ax = Axis(fig[1, 1],
        title=title,
        xlabel=xlabel,
        ylabel=ylabel,
        aspect=AxisAspect(box_aspect),
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    limits!(ax, limits...)
    draw_coastline_polygons!(ax, coastline["longitude"], coastline["latitude"],
        color=color, debug=increment_debug(debug))
    oad(debug, "END plot_coastline()")
    return fig
end
export plot_coastline


"""
    plot_coastline!(coastline::Coastline; color=:bisque3, debug::Integer=0, kwargs...)

Add a coastline to an existing plot.

This shares several arguments with [`plot_coastline`](@ref), but not those
that could alter the geometry.  Note that the plot limits are inherited
from the existing plot, so `xlim` and `ylim` should not be supplied
in the `kwargs...` grouping.

# Arguments

- `coastline` a [`Coastline`](@ref) object, as constructed using [`coastline`](@ref) or [`Coastline`](@ref).

# Keywords

- `color` a color specification, with default being a light brown.

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

- `kwargs...` other arguments, passed to `plot`, e.g. `xlim` and `ylim` to control the plot view, `color` for the land colour, etc.
"""
function plot_coastline!(coastline::Coastline; color=:bisque3, debug::Integer=0, kwargs...)
    error("FIXME: recode plot_coastline!() for Makie")
    oad(debug, "plot_coastline!() START")
    oad(debug, "  kwargs...: $(kwargs...)")
    rval = plot!(coastline["longitude"], coastline["latitude"];
        xlims=xlims(), ylims=ylims(), # inherit from previous plot
        legend=false, seriestype=:shape,
        color=color, linecolor=:black, linewidth=0.5,
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
plot_coastline(cl, limits=(-70, -60, 42, 48))
scale_bar(100.0)
```
"""
function scale_bar(distance::Real=100.0; x=:left, y=:top, linewidth::Real=1.8, fontsize::Real=8,
    style=:Ibeam)
    error("FIXME: recode scale_bar() for Makie; also call it scale_bar!")
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

