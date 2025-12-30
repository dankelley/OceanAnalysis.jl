using FileIO, JLD2

"""
    plot_section(section::Section, which="map";
        xvar="latitude", yvar="pressure", debug::Int64=0, kwargs...)

# Arguments

- `section` a Section, as created with [`as_section`](@ref) or [`read_section`](@ref).

- `which` a String indicating the type of plot. So far, the only choice is `"map"`.

# Keywords

- `type` a Symbol indicating the type of plot, either `:contour` or `:heatmap`.

- `xvar` a String indicating what to put on the horizontal axis (one of `"distance"`, `"latitude"` or `"longitude"`).

- `yvar` a String indicating what to put on the vertical axis (one of `"depth"` "` or `"pressure"`).

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed down to lower-level plotting functions. A typical example is to set `size` to control the size of the plot.

# Examples

```julia
using OceanAnalysis
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
dir = get_section(url)
section = read_section(dir);
plot_section(section, "map")
```
"""
function plot_section(section::Section, which="map";
    type=:contour, xvar="latitude", yvar="pressure", debug::Int64=0, kwargs...)
    oad(debug, "plot_section(which=\"$which\") BEGIN")
    # assume all CTDs have the same data-column names
    fields = names(section.data[1].data)
    if which == "map"
        oad(debug, "  plotting a map")
        longitude = section["longitude"]
        latitude = section["latitude"]
        pl = plot(longitude, latitude,
            aspect_ratio=1.0 / cos(0.5 * sum(extrema(latitude)) * pi / 180),
            seriestype=:scatter, framestyle=:box, legend=false,
            markersize=2; kwargs...)
        plot_coastline!(coastline())
    elseif which in fields
        oad(debug, "  see if section is gridded")
        section_is_gridded(section) || error("cannot handle ungridded section; use grid_section() first")
        if xvar == "longitude"
            xlab = "Longitude [°E]"
            x = section["longitude"]
        elseif xvar == "latitude"
            xlab = "Latitude [°N]"
            x = section["latitude"]
        elseif xvar == "distance"
            xlab = "Distance [km]"
            x = geod_distance.(section["longitude"], section["latitude"],
                section["longitude"][1], section["latitude"][1])
        else
            error("xvar=\"$xvar\" not allowed; try \"Distance\", \"Latitude\", or \"Longitude\"")
        end
        if yvar == "depth"
            ylab = "Depth [m]"
            y = section.data[1]["z"]
        elseif yvar == "pressure"
            ylab = "Pressure [dbar]"
            y = section.data[1]["pressure"]
        elseif yvar == "z"
            ylab = "Vertical Coordinate [m]"
            y = section.data[1]["depth"]
        else
            error("yvar=\"$yvar\" not allowed; try \"depth\", \"pressure\", or \"z\"")
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
        if type == :contour
            pl = contour(x, y, z;
                contourlabels=true, color=:black, cbar=false, levels=levels,
                yflip=yvar == "pressure" || yvar == "depth" ? true : false,
                xlab=xlab, ylab=ylab, framestyle=:box,
                titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
                kwargs...)
        elseif type == :heatmap
            # Kludge required for Julia as of 2025-12-30 (see link in the debug message)
            kw = (; kwargs...)
            if haskey(kwargs, :ylim)
                oad(debug, "  Avoiding heatmap() error handling ylim together with yflip=true; see")
                oad(debug, "    https://discourse.julialang.org/t/heatmap-how-do-ylim-and-yflip-interact/134804/4")
                oad(debug, "  for discussion.")
                keep_y = kw[:ylim][1] .<= y .<= kw[:ylim][2]
            else
                keep_y = y .< Inf
            end
            color = :turbo
            yflip = yvar == "pressure" || yvar == "depth" ? true : false
            pl = heatmap(x, y[keep_y], z[keep_y, :],
                yflip=yflip, xlab=xlab, ylab=ylab, framestyle=:box, color=color,
                titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8;
                kwargs...)
        else
            error("type=$(repr(type)) not understood; please use :contour or :heatmap")
        end
    else
        error("unknown 'which' value '$which'; try one of the following: ", ["map"; fields])
    end
    oad(debug, "END plot_section()")
    pl
end
