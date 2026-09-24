using FileIO, JLD2

"""
    plot_section(section::Section; which="salinity",
        type=:contour, xvar=:latitude, yvar=:pressure, show_stations=true,
        debug=0, kwargs...)

    plot_section!(fig_pos, section::Section; which="salinity",
        type=:contour, xvar=:latitude, yvar=:pressure, show_stations=true,
        debug=0, kwargs...)

# Arguments

- `section` a Section, as created with [`as_section`](@ref) or [`read_section`](@ref).

- `which` a String indicating the name of the hydrographic variable to be
  plotted. This must be present in each of the [`Ctd`](@ref) objects stored
  within the `section.data`.  Another requirement is that the section has been
  gridded, using [`grid_section`](@ref). The plotting is done with `contour`,
  `contourf` or `heatmap` as directed by the `type` argument. If
  `show_stations` is true, then `vline` is used to draw vertical lines indicating
  station locations. Note that case 2, [`section_is_gridded`](@ref) is called
  first to ensure that the section has been gridded with [`grid_section`](@ref),
  with an error being reported if not.

# Keywords

- `type` a Symbol indicating the type of plot. This may be `:contour` for
  simple contours, `:contourf` (the default) for filled contours, or `:heatmap`
  for an image.

- `xvar` either a Symbol (which must be one of `:distance`, `:latitude` or
  `:longitude`) or a Tuple with two elements the first being a label for the x
  axis and the second being a vector of values for x that correspond to the
  stations in `section.data`.  See the Examples for a case in which sampling time
  is used for the Tuple case.

- `yvar` a Symbol, the permitted values of which are `:depth` and `:pressure`.

- `show_stations` a Bool value indicating whether to draw vertical gray dotted
  lines to indicate station locations on cross-section diagrams.

- `debug`: an optional integer value that, if it exceeds 0, indicates that
  debugging output should be printed during processing.

- `kwargs...` extra arguments that are parsed and handled according
  to the value of `type`. The permitted keywords are: `color`, `colormap`,
  `colorrange`, `fontsize`, `levels`, `limits`, `linewidth`, `xlabel`, `ylabel` and `title`.
  The first of these is used only if `type=:contour`, while the second
  and third only apply if `type` is `:contourf` or `:heatmap`. All
  the others apply to each plot type. Note that if `xlabel` and `ylabel`
  are not specified, then they will be set automatically based on
  the values of `xvar` and `yvar`.

# Examples

```julia
using OceanAnalysis
using GLMakie # or CairoMakie
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].< (-68.0)];
# Note that we must grid to get the cross-section diagrams
sg = grid_section(s);
plot_section(sg, "salinity", ylim=(0, 2000));
```
"""
function plot_section(section::Section; which="salinity",
    type=:contour, xvar=:latitude, yvar=:pressure, show_stations=true,
    debug=0, kwargs...)
    oad(debug, "plot_section() BEGIN")
    fig = Makie.Figure()
    ax, plot = plot_section!(fig[1, 1], section; which=which,
        type=type, xvar=xvar, yvar=yvar, show_stations=show_stations,
        debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_section()")
    return Makie.FigureAxisPlot(fig, ax, plot.main)
end
export plot_section

function plot_section!(fig_pos, section::Section; which="salinity",
    type=:contour, xvar=:longitude, yvar=:pressure, show_stations=true,
    debug::Integer=0, kwargs...)
    oad(debug, "plot_section!() BEGIN")
    oad(debug, "    see if section is gridded")
    section_is_gridded(section) || error("must use grid_section() on the section before plotting it")
    # assume all CTDs have the same data-column names
    fields = names(section.data[1].data)
    which in fields || error("which=\"$which\" not allowed; try one of the following: ", fields)
    type in (:contour, :contourf, :heatmap) || throw(ArgumentError("type=$(repr(type)) not allowed; try using :contour, :contourf or :heatmap"))
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    oad(debug, "    inferred the following from kwargs (or from defaults, or from the data):")
    color = pop!(kwargs_dict, :color, :black)
    oad(debug, "      • color:       $(oad_val(color))")
    colormap = pop!(kwargs_dict, :colormap, :turbo)
    oad(debug, "      • colormap:    $(oad_val(colormap))")
    colorrange = pop!(kwargs_dict, :colorrange, :auto)
    oad(debug, "      • colorrange:  $(oad_val(colorrange))")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "      • fontsize:    $(oad_val(fontsize))")
    levels = pop!(kwargs_dict, :levels, :auto)
    oad(debug, "      • levels:      $(oad_val(levels))")
    limits = pop!(kwargs_dict, :limits, :auto)
    oad(debug, "      • limits:      $(oad_val(limits))")
    linewidth = pop!(kwargs_dict, :linewidth, 1)
    oad(debug, "      • linewidth:   $(oad_val(linewidth))")
    xlabel = pop!(kwargs_dict, :xlabel, :auto)
    oad(debug, "      • xlabel:      $(oad_val(xlabel))")
    ylabel = pop!(kwargs_dict, :ylabel, :auto)
    oad(debug, "      • ylabel:      $(oad_val(ylabel))")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "      • title:       $(oad_val(title))")
    # Check for unhandled keywords
    if !isempty(kwargs_dict)
        error("plot_section!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: color, colormap, colorrange, fontsize, ",
            "levels, linewidth, xlabel, ylabel and title")
    end
    oad(debug, "    drawing the data")
    if xvar isa Symbol
        oad(debug, "    xvar is a Symbol")
        if xvar == :longitude
            if xlabel == :auto
                xlabel = "Longitude [°E]"
            end
            x = section["longitude"]
        elseif xvar == :latitude
            if xlabel == :auto
                xlabel = "Latitude [°N]"
            end
            x = section["latitude"]
        elseif xvar == :distance
            if xlabel == :auto
                xlabel = "Distance [km]"
            end
            x = geod_distance.(section["longitude"], section["latitude"],
                section["longitude"][1], section["latitude"][1])
        else
            error("xvar=$(repr(xvar)) not allowed; try :distance, :Latitude or :Longitude")
        end
    elseif xvar isa Tuple
        oad(debug, "    xvar is a Tuple")
        2 == length(xvar) || error("xvar is a Tuple, but its length is not 2")
        x = xvar[2]
        xlabel = xvar[1]
    else
        error("xvar must be a Symbol or a Tuple")
    end
    if yvar == :depth
        if ylabel == :auto
            ylabel = "Depth [m]"
        end
        y = section.data[1]["z"]
    elseif yvar == :pressure
        if ylabel == :auto
            ylabel = "Pressure [dbar]"
        end
        y = section.data[1]["pressure"]
    elseif yvar == :z
        if ylabel == :auto
            ylabel = "Vertical Coordinate [m]"
        end
        y = section.data[1]["depth"]
    else
        error("yvar=$(repr(yvar)) not allowed; try :depth, :pressure or :z")
    end
    if limits == :auto
        limits = (extend_extrema(x, 0.0)..., extend_extrema(y, 0.0)...)
    end
    ax = Makie.Axis(
        fig_pos[1, 1],
        xlabel=xlabel,
        ylabel=ylabel,
        title=title,
        limits=limits,
        yreversed=true,
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    oad(debug, "    set x=$(first(x,3)) (+ more) for yvar=$xvar")
    oad(debug, "    set y=$(first(y,3)) (+ more) for yvar=$yvar")
    oad(debug, "    using limits=$limits")
    oad(debug, "    assemble field for plotting")
    nrows, ncols = length(section.data[1]["pressure"]), length(section.data)
    z = zeros(nrows, ncols)
    #println("size(z): $(size(z))")
    for i in 1:ncols
        rval = section.data[i][which]
        z[:, i] = rval
    end
    # Set up levels
    oad(debug, "    Note: levels=$levels FIXME: delete this line")
    if levels == :auto
        levels = pretty(z)
        oad(debug, "    automatically set levels to $levels")
    elseif length(levels) == 1 && isa(levels, Integer)
        levels = pretty(z, levels)
        oad(debug, "    automatically set levels to $levels (using provided request for number of levels)")
    else
        oad(debug, "    using user-supplied levels")
    end
    oad(debug, "    putting x and y (and z) in ascending order")
    ix = sortperm(x)
    iy = sortperm(y)
    x = x[ix]
    y = y[iy]
    z = z[iy, ix]
    #<old>kw = (; kwargs...)
    #<old>if haskey(kwargs, :ylim)
    #<old>    oad(debug, "    avoiding heatmap() error handling ylim together with yflip=true; see")
    #<old>    oad(debug, "      https://discourse.julialang.org/t/heatmap-how-do-ylim-and-yflip-interact/134804/4")
    #<old>    oad(debug, "    for discussion.")
    #<old>    keep_y = kw[:ylim][1] .<= y .<= kw[:ylim][2]
    #<old>else
    #<old>    keep_y = y .< Inf
    #<old>end
    keep_y = y .< Inf
    y = y[keep_y]
    oad(debug, "    set up y")
    z = z[keep_y, :]
    oad(debug, "    set up z")
    if colorrange == :auto && type == :heatmap
        colorrange = extend_extrema(z, 0.0)
    end
    oad(debug, "    about to plot main with type=$(repr(type))")
    if type == :contour
        oad(debug, "    using contour() length(x)=$(length(x)), length(y)=$(length(y)), size(z)=$(size(z))")
        main = Makie.contour!(ax, x, y, z', color=color, linewidth=linewidth, levels=levels, labels=true)
    elseif type == :contourf
        oad(debug, "    FIXME: using contourf()")
        main = Makie.contourf!(ax, x, y, z', levels=levels, colormap=colormap)
    elseif type == :heatmap
        oad(debug, "    : using heatmap()")
        main = Makie.heatmap!(ax, x, y, z', colormap=colormap, colorrange=colorrange)
        #yflip=yvar == :pressure || yvar == :depth ? true : false,
        #xlab=xlab, ylab=ylab,
        #color=:turbo,
        #titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
        #kwargs...)
    else
        error("type=$(repr(type)) not allowed; try :contour, :contourf or :heatmap")
    end
    if show_stations
        oad(debug, "    drawing stations")
        #FIXME: vline!(x, color=RGBA(0.5, 0.5, 0.5, 0.7), linewidth=1, linestyle=:dot, label=false)
    end
    oad(debug, "END plot_section!()")
    return ax, (main=main,)
end
export plot_section!
