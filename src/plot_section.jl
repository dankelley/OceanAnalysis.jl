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
function plot_section(x, y, z, levels=:auto;
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

