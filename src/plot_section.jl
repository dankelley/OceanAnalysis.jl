using FileIO, JLD2

"""
    plot_section(section::Section, which="salinity";
        type=:contourf, xvar=:latitude, yvar=:pressure, debug::Int64=0, kwargs...)

# Arguments

- `section` a Section, as created with [`as_section`](@ref) or [`read_section`](@ref).

- `which` a String indicating the name of the hydrographic variable to be plotted. This must be present in each of the [`Ctd`](@ref) objects stored within the `section.data`.  Another requirement is that the section has been gridded, using [`grid_section`](@ref). The plotting is done with `contour`, `contourf` or `heatmap` as directed by the `type` argument. In each case, `kwargs...` is passed to the function to permit customization.  If `show_stations` is true, then `vline` is used to draw vertical lines indicating station locations. Note that case 2, [`section_is_gridded`](@ref) is called first to ensure that the section has been gridded with [`grid_section`](@ref), with an error being reported if not.

# Keywords

- `type` a Symbol indicating the type of plot. This may be `:contour` for simple contours, `:contourf` (the default) for filled contours, or `:heatmap` for an image.

- `xvar` either a Symbol (which must be one of `:distance`, `:latitude` or `:longitude`) or a Tuple with two elements the first being a label for the x axis and the second being a vector of values for x that correspond to the stations in `section.data`.  See the Examples for a case in which sampling time is used for the Tuple case.

- `yvar` a Symbol, the permitted values of which are `:depth` and `:pressure`.

- `show_stations` a Bool value indicating whether to draw vertical gray dotted lines to indicate station locations on cross-section diagrams.

- `debug`: an optional integer value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed down to lower-level plotting functions. For example, `size` controls the size of the plot, `xlim` and `ylim` control the viewing window, and `color` controls the colour.

# Examples

```julia
using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].< (-68.0)];
p1 = plot_stations(s, xlim=(-80, -65), ylim=(35, 43));
scale_bar(500);
# Note that we must grid to get the cross-section diagrams
sg = grid_section(s);
p2 = plot_section(sg, "salinity", ylim=(0, 2000));
p3 = plot_section(sg, "salinity", ylim=(0, 2000), xvar=("Time", sg["time"]));
l = @layout [a; b c];
plot(p1, p2, p3, layout=l, dpi=300, size=(800, 500))
```
"""
function plot_section(section::Section, which::String="salinity";
    type::Symbol=:contourf,
    xvar::Union{Symbol,Tuple}=:latitude,
    yvar=:pressure, show_stations::Bool=false,
    debug::Int64=0, kwargs...)
    oad(debug, "plot_section(which=\"$which\") BEGIN")
    oad(debug, "  see if section is gridded")
    section_is_gridded(section) || error("must use grid_section() on the section before plotting it")
    # assume all CTDs have the same data-column names
    fields = names(section.data[1].data)
    which in fields || error("which=\"$which\" not allowed; try one of the following: ", fields)
    type in (:contour, :contourf, :heatmap) || throw(ArgumentError("type=$(repr(type)) not allowed; try using :contour, :contourf or :heatmap"))
    if xvar isa Symbol
        oad(debug, "  xvar is a Symbol")
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
        oad(debug, "  xvar is a Tuple")
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
    oad(debug, "  set x=$(first(x,3)) (+ more) for yvar=$xvar")
    oad(debug, "  set y=$(first(y,3)) (+ more) for yvar=$yvar")
    oad(debug, "  assemble field for plotting")
    nrows, ncols = length(section.data[1]["pressure"]), length(section.data)
    z = zeros(nrows, ncols)
    #println("size(z): $(size(z))")
    for i in 1:ncols
        rval = section.data[i][which]
        #println("i=4i, size(rval): $(size(rval))")
        z[:, i] = rval
    end
    levels = pretty(z, 12)
    oad(debug, "  levels: $levels")
    oad(debug, "  putting x and y (and z) in ascending order")
    ix = sortperm(x)
    iy = sortperm(y)
    x = x[ix]
    y = y[iy]
    z = z[iy, ix]
    # Kludge required for Julia as of 2025-12-30 (see link in the debug message)
    # (Actually, I think this is only needed for heatmap.)
    oad(debug, "  applying a patch to avoid a heatmap problem")
    kw = (; kwargs...)
    if haskey(kwargs, :ylim)
        oad(debug, "  Avoiding heatmap() error handling ylim together with yflip=true; see")
        oad(debug, "    https://discourse.julialang.org/t/heatmap-how-do-ylim-and-yflip-interact/134804/4")
        oad(debug, "  for discussion.")
        keep_y = kw[:ylim][1] .<= y .<= kw[:ylim][2]
    else
        keep_y = y .< Inf
    end
    y = y[keep_y]
    z = z[keep_y, :]
    # ok, now can plot

    if type == :contour
        oad(debug, "  using contour()")
        pl = contour(x, y, z;
            contourlabels=true, color=:black, cbar=false, levels=levels,
            yflip=yvar == :pressure || yvar == :depth ? true : false,
            xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
            titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
            kwargs...)
    elseif type == :contourf
        oad(debug, "  using contourf()")
        jldsave("dan.jld2"; x, y, z)
        pl = contourf(x, y, z;
            contourlabels=true, color=:turbo, cbar=false, levels=levels,
            yflip=yvar == :pressure || yvar == :depth ? true : false,
            xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
            titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
            kwargs...)
    elseif type == :heatmap
        oad(debug, "  using heatmap()")
        pl = heatmap(x, y, z;
            yflip=yvar == :pressure || yvar == :depth ? true : false,
            xlab=xlab, ylab=ylab, framestyle=:box, color=:turbo, tickdirection=:out,
            titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
            kwargs...)
    else
        error("type=$(repr(type)) not allowed; try :contour, :contourf or :heatmap")
    end
    if show_stations
        oad(debug, "  drawing stations")
        vline!(x, color=RGBA(0.5, 0.5, 0.5, 0.7), linewidth=1, linestyle=:dot, label=false)
    end
    oad(debug, "END plot_section()")
    pl
end

