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
  `contourf` or `heatmap` as directed by the `type` argument. In each case,
  `kwargs...` is passed to the function to permit customization.  If
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

- `kwargs`: optional items, passed down to lower-level plotting functions.

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
        debug=increment_debug(debug), kwargs=kwargs)
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
    if xvar isa Symbol
        oad(debug, "    xvar is a Symbol")
        if xvar == :longitude
            xlab = "Longitude [°E]"
            x = section["longitude"]
        elseif xvar == :latitude
            xlab = "Latitude [°N]"
            x = section["latitude"]
        elseif xvar == :distance
            xlab = "Distance [km]"
            x = geod_distance.(section["longitude"], section["latitude"],
                section["longitude"][1], section["latitude"][1])
        else
            error("xvar=$(repr(xvar)) not allowed; try :distance, :Latitude or :Longitude")
        end
    elseif xvar isa Tuple
        oad(debug, "    xvar is a Tuple")
        2 == length(xvar) || error("xvar is a Tuple, but its length is not 2")
        x = xvar[2]
        xlab = xvar[1]
    else
        error("xvar must be a Symbol or a Tuple")
    end
    if yvar == :depth
        ylab = "Depth [m]"
        y = section.data[1]["z"]
    elseif yvar == :pressure
        ylab = "Pressure [dbar]"
        y = section.data[1]["pressure"]
    elseif yvar == :z
        ylab = "Vertical Coordinate [m]"
        y = section.data[1]["depth"]
    else
        error("yvar=$(repr(yvar)) not allowed; try :depth, :pressure or :z")
    end
    # FIXME: process kwargs properly (and document)
    # FIXME: add fontsizes to ax
    ax = Makie.Axis(fig_pos[1, 1], xlabel=xlab, ylabel=ylab, yreversed=true)
    oad(debug, "    set x=$(first(x,3)) (+ more) for yvar=$xvar")
    oad(debug, "    set y=$(first(y,3)) (+ more) for yvar=$yvar")
    oad(debug, "    assemble field for plotting")
    nrows, ncols = length(section.data[1]["pressure"]), length(section.data)
    z = zeros(nrows, ncols)
    #println("size(z): $(size(z))")
    for i in 1:ncols
        rval = section.data[i][which]
        z[:, i] = rval
    end
    levels = pretty(z, 12)
    oad(debug, "    levels: $levels")
    oad(debug, "    putting x and y (and z) in ascending order")
    ix = sortperm(x)
    iy = sortperm(y)
    x = x[ix]
    y = y[iy]
    z = z[iy, ix]
    kw = (; kwargs...)
    if haskey(kwargs, :ylim)
        oad(debug, "    avoiding heatmap() error handling ylim together with yflip=true; see")
        oad(debug, "      https://discourse.julialang.org/t/heatmap-how-do-ylim-and-yflip-interact/134804/4")
        oad(debug, "    for discussion.")
        keep_y = kw[:ylim][1] .<= y .<= kw[:ylim][2]
    else
        keep_y = y .< Inf
    end
    y = y[keep_y]
    oad(debug, "    set up y")
    z = z[keep_y, :]
    oad(debug, "    set up z")
    # ok, now can plot
    oad(debug, "    about to plot main with type=$(repr(type))")
    if type == :contour
        oad(debug, "    using contour() length(x)=$(length(x)), length(y)=$(length(y)), size(z)=$(size(z))")
        main = Makie.contour!(ax, x, y, z')
        #contourlabels=true, color=:black, cbar=false, levels=levels,
        #yflip=yvar == :pressure || yvar == :depth ? true : false,
        #xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
        #titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
        #kwargs...)
    elseif type == :contourf
        oad(debug, "    FIXME: using contourf()")
        main = Makie.contourf!(ax, x, y, z')
        #contourlabels=true, color=:turbo, cbar=false, levels=levels,
        #yflip=yvar == :pressure || yvar == :depth ? true : false,
        #xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
        #titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
        #kwargs...)
    elseif type == :heatmap
        oad(debug, "    : using heatmap()")
        main = Makie.heatmap!(ax, x, y, z')
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
