"""
    plot_section(x, y, z, levels=:auto;
        title="", xlab="Distance from Shore [km]", ylab="Pressure [db]",
        font_size=8, show_stations=true, dpi=200, kwargs...)

Draw an oceanographic section plot, with contours for `z` as a function
of `x` and `y`. This is a preliminary version of the function, subject
to changes that are suggested by every-day work.

Note that `x` and `y` must each be ordered, because `contour()` insists
on that. The other options ought to be reasonably self-explanatory.

"""
function plot_section_old(x, y, z, levels=:auto;
    title="", xlab="Distance from Shore [km]", ylab="Pressure [db]",
    font_size=8, show_stations=true, dpi=200, kwargs...)
    if levels == :auto
        levels = pretty(z, 10)
    end
    rval = contour(x, y, z, yflip=true, color=:black,
        xlab=xlab, ylab=ylab, title=title, titlelocation=:left,
        framestyle=:box, levels=levels, cbar=false, clabels=true,
        tickdirection=:out, titlefontsize=font_size, labelfontsize=font_size, tickfontsize=font_size,
        dpi=dpi, kwargs...)
    if show_stations
        xlim, ylim = xlims(), ylims()
        for xx in x
            plot!(repeat([xx], 2), collect(ylim), xlim=xlim, ylim=ylim,
                seriestype=:path, color=:lightgray, linewidth=0.75, grid=false, label=false)
        end
    end
    rval
end


"""
    plot_section(section::Section, which="map";
        xvar="latitude", yvar="pressure", debug::Int64=0)

# Arguments

- `section` a Section, as created with [`as_section`](@ref) or [`read_section`](@ref).

- `which` a String indicating the type of plot. So far, the only choice is `"map"`.

# Keywords

- `xvar` a String indicating what to put on the horizontal axis (one of `"distance"`, `"latitude"` or `"longitude"`).

- `yvar` a String indicating what to put on the vertical axis (one of `"depth"` "` or `"pressure"`).

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

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
    xvar="latitude", yvar="pressure", debug::Int64=0)
    oad(debug, "plot_section(which=\"$which\") BEGIN")
    # assume all CTDs have the same data-column names
    fields = names(section.data[1].data)
    if which == "map"
        longitude = get_element(section, "longitude")
        latitude = get_element(section, "latitude")
        pl = plot(longitude, latitude,
            aspect_ratio=1.0 / cos(0.5 * sum(extrema(latitude)) * pi / 180),
            seriestype=:scatter, framestyle=:box, legend=false,
            markersize=2)
        plot_coastline!(coastline())
    elseif which in fields
        oad(debug, "    which=$which is a permitted field")
        xvar_allowed = ("longitude", "latitude", "distance")
        yvar_allowed = ("depth", "pressure")
        xvar in xvar_allowed ||
            error("xvar=\"$xvar\" not allowed; try one of the following: ", xvar_allowed)
        yvar in yvar_allowed ||
            error("yvar=\"$yvar\" not allowed; try one of the following: ", yvar_allowed)
        if !section_is_gridded(section)
            error("section is not gridded; try using section_grid() first")
        end
        oad(debug, "  assemble field for plotting")
        pl = "FIXME: write code to handle which=$which"
        # FIXME: extract field to matrix, then contour
        # FIXME: permit contouring or heatmaps
    else
        error("unknown 'which' value '$which'; try one of the following: ", ["map"; fields])
    end
    oad(debug, "END plot_section()")
    pl
end


