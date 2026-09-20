"""
    plot_coastline_polygons!(ax, longitude, latitude; linewidth=0.5,
        color=:bisque3, debug=0)

Draw a coastline as a group of polygons.

This is used by [`plot_coastline`](@ref) and possibly other functions.
Coastline data are stored as `longitude` and `latitude` vectors with `NaN`
separating individual land-mass rings (this is the convention Plots'
`seriestype=:shape` relied on). Makie has no direct equivalent, so this splits
the vectors on `NaN` and fills each ring separately with `poly!`.
"""
function plot_coastline_polygons!(ax, longitude, latitude; linewidth=0.5,
    color=:bisque3, debug=0)
    oad(debug, "plot_coastline_polygons!() START")
    oad(debug, "    linewidth: $linewidth")
    oad(debug, "    color:     $(repr(color))")
    polygons = Polygon{2,Float32}[]
    start = 1
    n = length(longitude)
    oad(debug, "    length(longitude): $n")
    oad(debug, "    assembling polygons")
    for i in 1:n+1
        if i == n + 1 || isnan(longitude[i]) || isnan(latitude[i])
            if i - start >= 3
                ring = Makie.Point2f.(longitude[start:i-1], latitude[start:i-1])
                push!(polygons, Polygon(ring))
            end
            start = i + 1
        end
    end
    oad(debug, "    aassembled $(length(polygons)) polygons")
    oad(debug, "    plotting the assembled polygons")
    if !isempty(polygons)
        if color == :white
            rval = Makie.poly!(ax, polygons, strokewidth=linewidth, strokecolor=:black)
        else
            rval = Makie.poly!(ax, polygons, color=color, strokewidth=linewidth, strokecolor=:black)
        end
        oad(debug, "END plot_coastline_polygons!()")
        return rval
    else
        error("this coastline object contains no polygons")
    end
end
# not exported


"""
    plot_coastline(coastline::Coastline; scalebar=false,
        debug=0, kwargs...)

    plot_coastline!(fig_pos, coastline::Coastline; scalebar=false,
        debug::Integer=0, kwargs...)

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
  `style` (which in this version must be `:Ibeam`).

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

- `kwargs...` other named arguments. Use `limits` to set the plot domain (with
  default `(-180.0,180.0,-90.0,90.0)` to show the whole world.  Use `color` to
  set the land color (with default `bisque3`). Use `linewidth` (default 1) to
  set the width of coastlines). Use `xlabel`, `ylabel` and `title` in the usual
  way for Makie plots. Use `fontsize` (which defaults to 8) to set the font
  size for axes and titles.

# Return value

The `plot_coastline` form returns a Makie `FigureAxisPlot`, which can be displayed
directly or saved with the FileIO's `save`.

The `plot_coastline!` form returns a Tuple with `ax` (a Makie `Axis`) as the first
item, and a NamedTuple as the second. The latter contains an element named
`main` that holds the main plot.

# Examples

```julia
# Show waters near Nova Scotia, with Station 3 of the Halifax Line
# indicated as HL3.
using OceanAnalysis
using GLMakie # or CairoMakie

# This function (perhaps extended) could be useful more generally.
function show_place(longitude, latitude, text;
    color=:blue, align=(:center, :top), offset=(0, -4))
    Makie.scatter!(longitude, latitude, color=color)
    Makie.text!(longitude, latitude, text=text, align=align, offset=offset, color=color)
end

cl = coastline();
fig = plot_coastline(cl, limits=(-67, -58, 43, 47.5))
show_place(-62.883, 43.883, "HL3")
#save("plot_coastline_example.png", fig, px_per_unit=4)
```
"""
function plot_coastline(coastline::Coastline; scalebar=false, debug=0, kwargs...)
    oad(debug, "plot_coastline() START")
    fig = Makie.Figure()
    ax, plots = plot_coastline!(fig[1, 1], coastline; scalebar=scalebar, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_coastline()")
    return Makie.FigureAxisPlot(fig, ax, plots.land)
end
export plot_coastline

function plot_coastline!(fig_pos, coastline::Coastline; scalebar=false,
    debug::Integer=0, kwargs...)
    oad(debug, "plot_coastline!() START")
    oad(debug, "    scalebar=$scalebar (originally)")
    # Check scalebar (used near the end of this function)
    if scalebar == true
        scalebar = (distance=100.0,) # defaults for other entries are added later
        gave_scalebar = true
    elseif scalebar == false
        gave_scalebar = false
    elseif isa(scalebar, NamedTuple)
        gave_scalebar = true
    else
        error("scalebar must be a Bool or a NamedTuple")
    end
    if gave_scalebar
        (:distance in keys(scalebar)) || error("scalebar must have an entry called `distance`")
    end
    oad(debug, "    gave_scalebar: $gave_scalebar")
    oad(debug, "    processing kwargs...")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    color = pop!(kwargs_dict, :color, :bisque3)
    oad(debug, "      • color:     $(oad_val(color))")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "      • fontsize: $(oad_val(fontsize))")
    linewidth = pop!(kwargs_dict, :linewidth, 0.5)
    oad(debug, "      • linewidth: $(oad_val(linewidth))")
    lims = pop!(kwargs_dict, :limits, (-180.0, 180.0, -90.0, 90.0))
    oad(debug, "      • limits:    $(oad_val(lims))")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "      • title:     $(oad_val(title))")
    xlabel = pop!(kwargs_dict, :xlabel, "")
    oad(debug, "      • xlabel:    $(oad_val(xlabel))")
    ylabel = pop!(kwargs_dict, :ylabel, "")
    oad(debug, "      • ylabel:    $(oad_val(ylabel))")
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
    ax = Makie.Axis(fig_pos[1, 1],
        title=title,
        xlabel=xlabel,
        ylabel=ylabel,
        aspect=Makie.AxisAspect(box_aspect),
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    Makie.limits!(ax, lims...)
    land_plt = plot_coastline_polygons!(ax, coastline["longitude"], coastline["latitude"];
        color=color, linewidth=linewidth, debug=increment_debug(debug))
    if gave_scalebar # FIXME: possibly (re)make this as a function
        oad(debug, "    drawing scalebar")
        distance = scalebar.distance
        (distance > 0.0) || error("scalebar.distance must be > 0, but it is $distance")
        scalebar_color = (:color in keys(scalebar)) ? scalebar.color : :black
        x = (:x in keys(scalebar)) ? scalebar.x : :left
        y = (:y in keys(scalebar)) ? scalebar.y : :top
        style = (:style in keys(scalebar)) ? scalebar.style : :Ibeam
        style == :Ibeam || error("style must be :Ibeam, but it is $(repr(style))")
        scalebar_linewidth = (:linewidth in keys(scalebar)) ? scalebar.linewidth : 1.8
        oad(debug, "    scalebar parameters: distance=$distance, x=$(repr(x)), y=$(repr(y)), style=$(repr(style)), linewidth=$(scalebar_linewidth)")
        A = ax.finallimits[]
        xmin, ymin = minimum(A)
        xmax, ymax = maximum(A)
        #oad(debug, "    xmin=$xmin, xmax=$xmax")
        #oad(debug, "    ymin=$ymin, ymax=$ymax")
        xmid = (xmin + xmax) / 2.0
        ymid = (ymin + ymax) / 2.0
        oad(debug, "    xmid=$xmid, ymid=$ymid")
        km_per_degree_lon = geod_distance(xmid - 0.5, ymid, xmid + 0.5, ymid)
        oad(debug, "    km_per_degree_lon: $km_per_degree_lon")
        dx = (xmax - xmin) / 20.0 # FIXME: may need to adjust the divisor to look nice
        dy = (ymax - ymin) / 15.0
        oad(debug, "    dx=$dx, dy=$dy")
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
        oad(debug, "    X=$X")
        oad(debug, "    Y=$Y")
        if style == :Ibeam
            DY = 0.2 * dy
            oad(debug, "    DY=$DY")
            X = [X[1], X[1], X[1], X[2], X[2], X[2]]
            Y = [Y[1] + DY, Y[1] - DY, Y[1], Y[2], Y[2] + DY, Y[2] - DY]
        elseif style != :line
            error("style $(repr(style)) not handled; try :line or :Ibeam")
        end
        oad(debug, "    X: $X")
        oad(debug, "    Y: $Y")
        sb_lines_plt = Makie.lines!(ax, X, Y, color=scalebar_color, linewidth=scalebar_linewidth)
        sb_text_plt = Makie.text!(ax, "$(trunc(Int, distance)) km", align=(:center, :center),
            position=((X[1] + X[end]) / 2.0, y0 + 0.5 * dy), color=scalebar_color,
            fontsize=fontsize)
    else
        sb_lines_plt = nothing
        sb_text_plt = nothing
    end
    oad(debug, "END plot_coastline()")
    return ax, (land=land_plt, scalebar_lines=sb_lines_plt, scalebar_text=sb_text_plt)
end
export plot_coastline!


#<broken> """
#<broken>     scalebar!(ax, distance::Real=100.0;
#<broken>         x=:left, y=:top, style=:Ibeam, debug=0, kwargs...)
#<broken> 
#<broken> Add a horizontal scalebar to a plot made with [`plot_coastline`]@ref).
#<broken> 
#<broken> # Arguments
#<broken> 
#<broken> - `ax` a Makie Axis.
#<broken> - `distance` distance to be indicated, in km.
#<broken> 
#<broken> # Keywords
#<broken> 
#<broken> - `x` a Symbol (either `:left` or `:right`), or a number indicating longitude.
#<broken> - `y` a Symbol (either `:bottom` or `:top`), or a number indicating latitude.
#<broken> - `style` a Symbol indicating the desired way to represent the distance bar.
#<broken>   With `style=:Ibeam` (the default), an Ibeam shape is drawn, with 2/3 of
#<broken>   `linewidth`. With `style=:line`, distance is represented by a single line that
#<broken>   is drawn at the `linewidth`.
#<broken> - `kwargs` other arguments used in plotting. The only possibilities are
#<broken>   `linewidth` (which defaults to 1.8) and `color` (which defaults to `:black`).
#<broken> 
#<broken> # Examples
#<broken> 
#<broken> ```julia
#<broken> # FIXME: BROKEN
#<broken> #using OceanAnalysis
#<broken> #using GLMakie # or CairoMakie
#<broken> #cl = coastline();
#<broken> #ax, fig = plot_coastline(cl, limits=(-67, -58, 43, 47.5))
#<broken> #scalebar!(ax, 10.0)
#<broken> ```
#<broken> """
#<broken> function plot_scalebar!(ax, distance::Real=100.0;
#<broken>     x=:left, y=:top, style=:Ibeam, debug=0, kwargs...)
#<broken>     oad(debug, "scalebar!() START")
#<broken>     distance > 0.0 || throw(ArgumentError("distance must be a positive number, but it is $distance"))
#<broken>     kwargs_dict = Dict{Symbol,Any}(kwargs)
#<broken>     color = pop!(kwargs_dict, :color, :black)
#<broken>     linewidth = pop!(kwargs_dict, :linewidth, 1.8)
#<broken>     oad(debug, "    color: $(oad_val(color)) (can be set in kwargs)")
#<broken>     oad(debug, "    linewidth: $linewidth (can be set in kwargs)")
#<broken>     if !isempty(kwargs_dict)
#<broken>         error("scalebar!() does not recognize keywords: ",
#<broken>             join(string.(keys(kwargs_dict)), ", "),
#<broken>             ". The permitted keywords are: color and linewidth")
#<broken>     end
#<broken>     A = ax.finallimits[]
#<broken>     xmin, ymin = minimum(A)
#<broken>     xmax, ymax = maximum(A)
#<broken>     oad(debug, "    xmin=$xmin, xmax=$xmax")
#<broken>     oad(debug, "    ymin=$ymin, ymax=$ymax")
#<broken>     xmid = (xmin + xmax) / 2.0
#<broken>     ymid = (ymin + ymax) / 2.0
#<broken>     km_per_degree_lon = geod_distance(xmid - 0.5, ymid, xmid + 0.5, ymid)
#<broken>     oad(debug, "    km_per_degree_lon: $km_per_degree_lon")
#<broken>     dx = (xmax - xmin) / 20.0 # FIXME: may need to adjust the divisor to look nice
#<broken>     dy = (ymax - ymin) / 15.0
#<broken>     if x == :left
#<broken>         X = xmin + dx .+ [0.0, distance / km_per_degree_lon]
#<broken>     elseif x == :right
#<broken>         X = xmax - dx .- [0.0, distance / km_per_degree_lon]
#<broken>     elseif isa(x, Number)
#<broken>         X = x .+ [0.0, distance / km_per_degree_lon]
#<broken>     else
#<broken>         throw(ArgumentError("x must be :left, :right, or a number, but it is $(repr(x))"))
#<broken>     end
#<broken>     if y == :top
#<broken>         y0 = ymax - dy
#<broken>     elseif y == :bottom
#<broken>         y0 = ymin + dy
#<broken>     elseif isa(y, Number)
#<broken>         y0 = y
#<broken>     else
#<broken>         throw(ArgumentError("y must be :top, :bottom, or a number, but it is $(repr(y))"))
#<broken>     end
#<broken>     Y = [y0, y0]
#<broken>     if style == :Ibeam
#<broken>         linewidth = 2.0 * linewidth / 3.0
#<broken>         DY = (X[2] - X[1]) / 30
#<broken>         X = [X[1], X[1], X[1], X[2], X[2], X[2]]
#<broken>         Y = [Y[1] + DY, Y[1] - DY, Y[1], Y[2], Y[2] + DY, Y[2] - DY]
#<broken>     elseif style != :line
#<broken>         error("style $(repr(style)) not handled; try :line or :Ibeam")
#<broken>     end
#<broken>     oad(debug, "    X: $X")
#<broken>     oad(debug, "    Y: $Y")
#<broken>     lines!(ax, X, Y, color=color, linewidth=linewidth)
#<broken>     text!(ax, "$(trunc(Int, distance)) km", align=(:center, :center),
#<broken>         position=((X[1] + X[end]) / 2.0, y0 + dy / 3.0), color=color)
#<broken>     oad(debug, "END plot_scalebar!()")
#<broken> end
#<broken> # BROKEN SO NOT EXPORTED export plot_scalebar!
#<broken> 
