using FileIO, JLD2

"""
    plot_section(section::Section, which="map";
        type=:contourf, xvar=:latitude, yvar=:pressure, debug::Int64=0, kwargs...)

# Arguments

- `section` a Section, as created with [`as_section`](@ref) or [`read_section`](@ref).

- `which` a String indicating the type of plot. There are two main options. The first (and default) option is to use `"map"`,  to get a station map. The points are drawn with [`scatter`](@ref), and `kwargs...` is passed to that function, to permit altering the symbol shape, size, colour, etc. The second option creates cross-section diagrams, plotting the named variable as stored within the constituent [`Ctd`](@ref) elements of `section`. The data are drawn with [`contour`](@ref), [`contourf`](@ref) or [`heatmap`](@ref), and `kwargs...` is passed to whichever is chosen, to permit customization.  Note that in the second option, [`is_section_gridded`](@ref) is called first to ensure that the section has been gridded with [`grid_section`](@ref), with an error being reported if not.

# Keywords

- `type` a Symbol indicating the type of plot. This may be `:contour` for simple contours, `:contourf` (the default) for filled contours, or `:heatmap` for an image.

- `xvar` a Symbol, used only on cross-section diagrams, indicating what to put on the horizontal axis (one of `:distance`, `:latitude` or `:longitude`).

- `yvar` as `xvar`, but for the y axis. The permitted values are `:depth` and `:pressure`.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed down to lower-level plotting functions. For example, `size` controls the size of the plot, `xlim` and `ylim` control the viewing window, and `color` controls the colour.

# Examples

```juliadoc
using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].<-68.0];
sg = grid_section(s);

p1 = plot_section(s, xlim=(-80, -65), ylim=(35, 43));
scale_bar(500);
p2 = plot_section(sg, "salinity", ylim=(0, 2000));
p3 = plot_section(sg, "temperature", ylim=(0, 2000));
l = @layout [a; b c]
plot(p1, p2, p3, layout=l, dpi=300);
```
"""
function plot_section(section::Section, which="map";
    type=:contourf, xvar=:latitude, yvar=:pressure, debug::Int64=0, kwargs...)
    oad(debug, "plot_section(which=\"$which\") BEGIN")
    # assume all CTDs have the same data-column names
    fields = names(section.data[1].data)
    if which == "map"
        oad(debug, "  plotting a map")
        longitude = section["longitude"]
        latitude = section["latitude"]
        pl = scatter(longitude, latitude;
            aspect_ratio=1.0 / cos(0.5 * sum(extrema(latitude)) * pi / 180),
            framestyle=:box, legend=false,
            markershape=:xcross, markercolor=:black, markersize=3,
            kwargs...)
        plot_coastline!(coastline())
    elseif which in fields
        oad(debug, "  see if section is gridded")
        section_is_gridded(section) || error("cannot handle ungridded section; use grid_section() first")
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
        ix = sortperm(x)
        iy = sortperm(y)
        x = x[ix]
        y = y[iy]
        z = z[iy, ix]
        # Kludge required for Julia as of 2025-12-30 (see link in the debug message)
        # (Actually, I think this is only needed for heatmap, but I'll do for all cases.)
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
            pl = contour(x, y, z;
                contourlabels=true, color=:black, cbar=false, levels=levels,
                yflip=yvar == :pressure || yvar == :depth ? true : false,
                xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
                titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
                kwargs...)
        elseif type == :contourf
            pl = contourf(x, y, z;
                contourlabels=true, color=:turbo, cbar=false, levels=levels,
                yflip=yvar == :pressure || yvar == :depth ? true : false,
                xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
                titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
                kwargs...)
        elseif type == :heatmap
            pl = heatmap(x, y, z;
                yflip=yvar == :pressure || yvar == :depth ? true : false,
                xlab=xlab, ylab=ylab, framestyle=:box, color=:turbo, tickdirection=:out,
                titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
                kwargs...)
        else
            error("type=$(repr(type)) not allowed; try :contour, :contourf or :heatmap")
        end
    else
        error("unknown 'which' value '$which'; try one of the following: ", ["map"; fields])
    end
    oad(debug, "END plot_section()")
    pl
end
