using FileIO, JLD2

"""
    plot_section(section::Section; which="salinity",
        type=:contour, xvar=:latitude, yvar=:pressure, show_stations=true,
        debug=0, kwargs...)

    plot_section!(fig_pos, section::Section; which="salinity",
        type=:contour, xvar=:latitude, yvar=:pressure, show_stations=true,
        debug=0, kwargs...)

Plot an oceanographic section for data contained in `section`, showing how the
variable named by `which` depends on either pressure or density (as
dictated by `yvar`) and various lateral coordinates (as dictated by
`xvar`).  The plot style is set by `which`, with the valid choices being
`:contour` (plain contours), `:contourf` (colour-filled contours),
`:contourf_contour` (colour-filled contours with added black contours),
or `:heatmap` (a coloured image).

The `plot_section()` function creates a single plot, and the
`plot_section!()` function adds to an existing plot.  See the Examples
section for illustrations of both cases.

These functions require a Makie backend to be loaded and activated by
the caller (e.g. `using CairoMakie` or `using GLMakie`) before they
are called.

*Note:* as of 2026-09-26, the Makie plotting library has a bug contouring
matrices that hold NaN values, with the result being that some (or all) contour
labels have lines running through them; see
https://github.com/MakieOrg/Makie.jl/issues/5811 for a bug report on this.

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
  simple contours, `:contourf` for filled contours, `:contourf_contour`
  (the default) for filled contours with black contourlines,
  or `:heatmap` for an image.

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
  Not all of these are used for all plot types.  Users familiar with
  Makie plotting can perhaps guess the possibilities. For example, `color`,
  `levels` and `linewidth` all relate to contour lines, so their values
  are only used if `type` is `:contour` or `:contourf_contour`.
  Simillary, `colormap` and `colorrange` control colour fields, so their
  values are only used if `type` is `:contourf`, `:contourf_contour` or `:heatmap`.
  The labelling elements, `xlabel`, `ylabel` and `title` all are given
  reasonable defaults (depending on `which`, `xvar` and `yvar`) if they are not
  specified in the function call.

# Return value

The `plot_section` form returns a Makie `FigureAxisPlot`, which can be
displayed directly or saved with the FileIO's `save`.

The `plot_section!` form returns a Tuple with `ax` (a Makie `Axis`) as the first
item, and a NamedTuple as the second. The latter contains an element named
`main` that holds the main plot, and, in the `:contourf` and `:heatmap` cases,
an element named `cb` that is a Colorbar.


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
# Illustrate three styles
fig = plot_section(sg, which="salinity", fontsize=12, levels=5,
    type=:contour, limits=(nothing, nothing, 0, 1500))
#save("0_plot_section_contour.png", fig, px_per_unit=4)
fig = plot_section(sg, which="salinity", fontsize=12, levels=30,
    type=:contourf, limits=(nothing, nothing, 0, 1500))
#save("0_plot_section_contourf.png", fig, px_per_unit=4)
fig = plot_section(sg, which="salinity", fontsize=12, levels=5,
    type=:heatmap, limits=(nothing, nothing, 0, 1500))
#save("0_plot_section_heatmap.png", fig, px_per_unit=4)
```
"""
function plot_section(section::Section; which="salinity",
    type=:contourf_contour, xvar=:latitude, yvar=:pressure, show_stations=true,
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
    type=:contourf_contour, xvar=:longitude, yvar=:pressure, show_stations=true,
    debug::Integer=0, kwargs...)
    oad(debug, "plot_section!() BEGIN")
    oad(debug, "    see if section is gridded")
    section_is_gridded(section) || error("must use grid_section() on the section before plotting it")
    # assume all CTDs have the same data-column names
    fields = names(section.data[1].data)
    which in fields || error("which=\"$which\" not allowed; try one of the following: ", fields)
    type in (:contour, :contourf, :contourf_contour, :heatmap) || throw(ArgumentError("type=$(repr(type)) not allowed; try using :contour, :contourf, :contourf_contour or :heatmap"))
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
    linewidth = pop!(kwargs_dict, :linewidth, 0.75) # thin to avoid mess
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
    ax = Makie.Axis(fig_pos[1, 1],
        xlabel=xlabel, ylabel=ylabel, title=title,
        limits=limits, yreversed=true,
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
    oad(debug, "    set up x (length $(length(x)))")
    y = y[iy]
    z = z[iy, ix]
    keep_y = y .< Inf
    y = y[keep_y]
    oad(debug, "    set up y (length $(length(y)))")
    z = z[keep_y, :]
    oad(debug, "    set up z (size $(size(z)))")
    @assert size(z) == (length(y), length(x)) "z is $(size(z)), but it ought to be $((length(y), length(x)))"
    if colorrange == :auto && type == :heatmap
        colorrange = extend_extrema(z, 0.0)
        oad(debug, "    colorrange=:auto automatically converted to colorrange=$colorrange")
    end
    oad(debug, "    about to plot main with type=$(repr(type))")
    if type == :contour
        oad(debug, "    using contour() length(x)=$(length(x)), length(y)=$(length(y)), size(z)=$(size(z))")
        main = Makie.contour!(ax, x, y, z', color=color, linewidth=linewidth, levels=levels, labels=true)
        if show_stations
            oad(debug, "    drawing stations") # FIXME: use a function for this
            ax_top = Makie.Axis(fig_pos[1, 1], xtickwidth=1.4, xticksize=6,
                xtickcolor=:black, xaxisposition=:top,
                xgridvisible=false, xticks=(x, repeat([""], length(x))))
            Makie.hideydecorations!(ax_top)
            Makie.hidespines!(ax_top, :l, :r, :b)
            Makie.linkxaxes!(ax, ax_top)
        end
    elseif type == :contourf || type == :contourf_contour
        oad(debug, "    FIXME: using contourf()")
        main = Makie.contourf!(ax, x, y, z', levels=levels, colormap=colormap)
        if type == :contourf_contour
            Makie.contour!(ax, x, y, z', levels=levels, color=:black, linewidth=linewidth)
        end
        if show_stations
            oad(debug, "    drawing stations") # FIXME: use a function for this
            ax_top = Makie.Axis(fig_pos[1, 1], xtickwidth=1.4, xticksize=5,
                xtickcolor=:black, xaxisposition=:top,
                xgridvisible=false, xticks=(x, repeat([""], length(x))))
            Makie.hideydecorations!(ax_top)
            Makie.hidespines!(ax_top, :l, :r, :b)
            Makie.linkxaxes!(ax, ax_top)
        end
        cb = Makie.Colorbar(fig_pos[1, 2], main, ticklabelsize=fontsize)
        # Apparently, in the past we could just use Makie.hlines as
        # below, but no more ... 2026-09-26.
        #   Makie.hlines!(cb, levels, color=:black, linewidth=1)
        cb_ax = Makie.Axis(fig_pos[1, 2], limits=(0, 1, minimum(levels), maximum(levels)))
        Makie.hidedecorations!(cb_ax)
        Makie.hidespines!(cb_ax)
        Makie.hlines!(cb_ax, levels, color=:black, linewidth=linewidth)
        oad(debug, "END plot_section!()")
        return ax, (main=main, cb=cb)
    elseif type == :heatmap
        oad(debug, "    : using heatmap()")
        main = Makie.heatmap!(ax, x, y, z', colormap=colormap, colorrange=colorrange)
        if show_stations
            oad(debug, "    drawing stations") # FIXME: use a function for this
            ax_top = Makie.Axis(fig_pos[1, 1], xtickwidth=1.4, xticksize=5,
                xtickcolor=:black, xaxisposition=:top,
                xgridvisible=false, xticks=(x, repeat([""], length(x))))
            Makie.hideydecorations!(ax_top)
            Makie.hidespines!(ax_top, :l, :r, :b)
            Makie.linkxaxes!(ax, ax_top)
        end
        cb = Makie.Colorbar(fig_pos[1, 2], main, ticklabelsize=fontsize)
        oad(debug, "END plot_section!()")
        return ax, (main=main, cb=cb)
    else
        error("type=$(repr(type)) not allowed; try :contour, :contourf or :heatmap")
    end
    oad(debug, "END plot_section!()")
    return ax, (main=main,)
end
export plot_section!
