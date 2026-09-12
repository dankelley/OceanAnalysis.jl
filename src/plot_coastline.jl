"""
    draw_coastline_polygons!(ax, longitude, latitude; linewidth=0.5,
        color=:bisque3, debug=0)

Draw a coastline as a group of polygons.

This is used by [`plot_coastline`](@ref) and possibly other functions.
Coastline data are stored as `longitude` and `latitude` vectors with `NaN`
separating individual land-mass rings (this is the convention Plots'
`seriestype=:shape` relied on). Makie has no direct equivalent, so this splits
the vectors on `NaN` and fills each ring separately with `poly!`.
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
            rval = poly!(ax, polygons, strokewidth=linewidth, strokecolor=:black)
        else
            rval = poly!(ax, polygons, color=color, strokewidth=linewidth, strokecolor=:black)
        end
        oad(debug, "END draw_coastline_polygons!()")
        return rval
    else
        error("this coastline object contains no polygons")
    end
end
# not exported


"""
    plot_coastline(coastline::Coastline; scalebar=false, debug=0, kwargs...)

Plot a coastline with cartesian longitude and latitude axes (i.e. without a map
projection).

The aspect ratio of the plot is set so as to preserve coastline shapes at the
central latitude of the plot view.

# Arguments

- `coastline` a [`Coastline`](@ref) object, as constructed using
  [`coastline`](@ref) or [`Coastline`](@ref).

# Keywords

- `scalebar` either a Bool value or a NamedTuple. If `scalebar` is a Bool
  value, then false means not to draw a scale-bar, and true means to draw a
  default one (showing distance 101km with an I-beam shape at the top-left of the
  plot panel). If `scalebar` is a Tuple, then it must hold 4 values: `distance`
  for the length (in km) to be shown; `x` to indicate the horizontal location on
  the diagram (which may be `:left`, `:right`, or a numerical value
  specifying longitude); `y` (which may be `:bottom`, `:top` or a numerical
  value specifying latitude); `linewidth` (which defaults to 1.8); and
  `style`, which in this version must be `:Ibeam`.

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

- `kwargs...` other named arguments. Use `limits` to set the plot domain (with
  default `(-180.0,180.0,-90.0,90.0)` to show the whole world.  Use `color` to
  set the land color (with default `bisque3`). Use `linewidth` (default 1) to
  set the width of coastlines). Use `xlabel`, `ylabel` and `title` in the usual
  way for Makie plots. Use `fontsize` to set the font size for axes and titles.

# Return value

The `plot_coastline` form returns a `Makie.Figure`, which can be displayed
directly or saved with `save("filename.png", fig)`.

The `plot_coastline!` form returns a NamedTuple containing `ax` (a
`Makie.Axis`), `plt` (a Makie object) and `cb` (a `Colorbar` object set to
nothing, present here only so all functions in the package return a
three-component NameTuple).

# Examples

```julia
using OceanAnalysis, GLMakie # or CairoMakie

# Example 1. world
plot_coastline(coastline(:global_coarse))

# Example 2. Maritime provinces, light-gray, with a scale-bar
fig = plot_coastline(coastline(), color=:lightgray, limits=(-67, -60, 43, 47))
scale_bar!(fig, 100.0, linewidth=1)
```
"""
function plot_coastline(coastline::Coastline; scalebar=false, debug=0, kwargs...)
    oad(debug, "plot_coastline() START")
    fig = Figure()
    ax, plt = plot_coastline!(fig[1, 1], coastline; scalebar=scalebar,
        debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_coastline()")
    return fig
end
export plot_coastline

function plot_coastline!(fig_pos, coastline::Coastline; scalebar=false,
    debug::Integer=0, kwargs...)
    oad(debug, "plot_coastline!() START")
    oad(debug, "    scalebar=$scalebar (originally)")
    # Check scalebar (used near the end of this function)
    gave_scalebar = false
    if scalebar == true
        scalebar = (distance=100.0, x=:left, y=:top, style=:Ibeam, linewidth=1.8)
        oad(debug, "    scalebar=$scalebar (after expansion)")
        gave_scalebar = true
    end
    if gave_scalebar
        isa(scalebar, NamedTuple) || error("scalebar, if given, must be a NamedTuple")
        (:distance in keys(scalebar)) || error("scalebar must have an entry called `distance`")
    end
    # Process kwargs...
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    color = pop!(kwargs_dict, :color, :bisque3)
    oad(debug, "    color=$color")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "    fontsize=$fontsize")
    linewidth = pop!(kwargs_dict, :linewidth, 8)
    oad(debug, "    linewidth=$linewidth")
    lims = pop!(kwargs_dict, :limits, (-180.0, 180.0, -90.0, 90.0))
    oad(debug, "    limits=$lims")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "    title=$title")
    xlabel = pop!(kwargs_dict, :xlabel, "")
    oad(debug, "    xlabel=$xlabel")
    ylabel = pop!(kwargs_dict, :ylabel, "")
    oad(debug, "    ylabel=$ylabel")
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: color, fontsize, linewidth, ",
            "limits, title, xlabel, and ylabel")
    end

    mid_latitude = 0.5 * (lims[3] + lims[4])
    oad(debug, "    computed mid_latitude=$mid_latitude")
    aspect_ratio = 1.0 / cos(mid_latitude * pi / 180.0)
    oad(debug, "    computed aspect_ratio=$aspect_ratio")
    box_aspect = (lims[2] - lims[1]) / ((lims[4] - lims[3]) * aspect_ratio)
    oad(debug, "    computed box_aspect=$box_aspect")
    ax = Axis(fig_pos[1, 1],
        title=title,
        xlabel=xlabel,
        ylabel=ylabel,
        aspect=AxisAspect(box_aspect),
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    limits!(ax, lims...)
    land_plt = draw_coastline_polygons!(ax, coastline["longitude"], coastline["latitude"],
        color=color, debug=increment_debug(debug))
    if gave_scalebar
        # distance=100.0, x=:left, y=:top, style=:Ibeam
        distance = scalebar.distance
        style = scalebar.style
        (distance > 0.0) || error("scalebar.distance must be > 0, but it is $distance")
        color = (:color in keys(scalebar)) ? scalebar.color : :black
        x = (:x in keys(scalebar)) ? scalebar.x : :left
        y = (:y in keys(scalebar)) ? scalebar.y : :top
        style == :Ibeam || error("style must be :Ibeam, but it is $(repr(style))")
        linewidth = (:linewidth in keys(scalebar)) ? scalebar.linewidth : 3.0 / 2.0
        oad(debug, "    scalebar parameters: distance=$distance, x=$(repr(x)), y=$(repr(y)), style=$(repr(style)), linewidth=$scalebar.linewidth")
        A = ax.finallimits[]
        xmin, ymin = minimum(A)
        xmax, ymax = maximum(A)
        oad(debug, "    xmin=$xmin, xmax=$xmax")
        oad(debug, "    ymin=$ymin, ymax=$ymax")
        xmid = (xmin + xmax) / 2.0
        ymid = (ymin + ymax) / 2.0
        oad(debug, "    xmid=$xmid, ymid=$ymid")
        km_per_degree_lon = geod_distance(xmid - 0.5, ymid, xmid + 0.5, ymid)
        oad(debug, "    km_per_degree_lon: $km_per_degree_lon")
        dx = (xmax - xmin) / 20.0 # FIXME: may need to adjust the divisor to look nice
        dy = (ymax - ymin) / 15.0
        if x == :left
            X = xmin + dx .+ [0.0, distance / km_per_degree_lon]
        elseif x == :right
            X = xmax - dx .- [0.0, distance / km_per_degree_lon]
        elseif isa(x, Number)
            X = x .+ [0.0, distance / km_per_degree_lon]
        else
            throw(ArgumentError("x must be :left, :right, or a number, but it is $(repr(x))"))
        end
        if y == :top
            y0 = ymax - dy
        elseif y == :bottom
            y0 = ymin + dy
        elseif isa(y, Number)
            y0 = y
        else
            throw(ArgumentError("y must be :top, :bottom, or a number, but it is $(repr(y))"))
        end
        Y = [y0, y0]
        oad(debug, "    Y=$Y")
        if style == :Ibeam
            DY = (X[2] - X[1]) / 30
            X = [X[1], X[1], X[1], X[2], X[2], X[2]]
            Y = [Y[1] + DY, Y[1] - DY, Y[1], Y[2], Y[2] + DY, Y[2] - DY]
        elseif style != :line
            error("style $(repr(style)) not handled; try :line or :Ibeam")
        end
        oad(debug, "    X: $X")
        oad(debug, "    Y: $Y")
        sb_lines_plt = lines!(ax, X, Y, color=color, linewidth=linewidth)
        sb_text_plt = text!(ax, "$(trunc(Int, distance)) km", align=(:center, :center),
            position=((X[1] + X[end]) / 2.0, y0 + dy / 3.0), color=color)
    else
        sb_lines_plt = nothing
        sb_text_plt = nothing
    end
    oad(debug, "END plot_coastline()")
    return ax, (land=land_plt, scalebar_lines=sb_lines_plt, scalebar_text=sb_text_plt)
end
export plot_coastline!


"""
    scale_bar!(fig, distance::Real=100.0;
        x=:left, y=:top, style=:Ibeam, debug=0, kwargs...)

Add a horizontal scalebar to a plot made with [`plot_coastline`]@ref).

# Arguments

- `ax` FIXME
- `distance` distance to be indicated, in km.

# Keywords

- `x` a Symbol (either `:left` or `:right`), or a number indicating longitude.
- `y` a Symbol (either `:bottom` or `:top`), or a number indicating latitude.
- `style` a Symbol indicating the desired way to represent the distance bar.
  With `style=:Ibeam` (the default), an Ibeam shape is drawn, with 2/3 of
  `linewidth`. With `style=:line`, distance is represented by a single line that
  is drawn at the `linewidth`.
- `kwargs` other arguments used in plotting. The only possibilities are
  `linewidth` (which defaults to 1.8) and `color` (which defaults to `:black`).

# Examples

```julia
using OceanAnalysis, Plots
cl = coastline();
fig = plot_coastline(cl, limits=(-70, -60, 42, 48))
scale_bar!(fig, 100.0)
```
"""
function scale_bar!(fig, distance::Real=100.0;
    x=:left, y=:top, style=:Ibeam, debug=0, kwargs...)
    oad(debug, "scale_bar!() START")
    distance > 0.0 || throw(ArgumentError("distance must be a positive number, but it is $distance"))
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    color = pop!(kwargs_dict, :color, :black)
    linewidth = pop!(kwargs_dict, :linewidth, 1.8)
    oad(debug, "    color: $(oad_val(color)) (can be set in kwargs)")
    oad(debug, "    linewidth: $linewidth (can be set in kwargs)")
    if !isempty(kwargs_dict)
        error("scale_bar!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: color and linewidth")
    end
    ax = current_axis(fig) # FIXME: make plot_coasline() return ax,fig,plt???
    A = ax.finallimits[]
    xmin, ymin = minimum(A)
    xmax, ymax = maximum(A)
    oad(debug, "    xmin=$xmin, xmax=$xmax")
    oad(debug, "    ymin=$ymin, ymax=$ymax")
    xmid = (xmin + xmax) / 2.0
    ymid = (ymin + ymax) / 2.0
    km_per_degree_lon = geod_distance(xmid - 0.5, ymid, xmid + 0.5, ymid)
    oad(debug, "    km_per_degree_lon: $km_per_degree_lon")
    dx = (xmax - xmin) / 20.0 # FIXME: may need to adjust the divisor to look nice
    dy = (ymax - ymin) / 15.0
    if x == :left
        X = xmin + dx .+ [0.0, distance / km_per_degree_lon]
    elseif x == :right
        X = xmax - dx .- [0.0, distance / km_per_degree_lon]
    elseif isa(x, Number)
        X = x .+ [0.0, distance / km_per_degree_lon]
    else
        throw(ArgumentError("x must be :left, :right, or a number, but it is $(repr(x))"))
    end
    if y == :top
        y0 = ymax - dy
    elseif y == :bottom
        y0 = ymin + dy
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
    oad(debug, "    X: $X")
    oad(debug, "    Y: $Y")
    lines!(ax, X, Y, color=color, linewidth=linewidth)
    text!(ax, "$(trunc(Int, distance)) km", align=(:center, :center),
        position=((X[1] + X[end]) / 2.0, y0 + dy / 3.0), color=color)
    oad(debug, "END scale_bar!()")
end
export scale_bar!

