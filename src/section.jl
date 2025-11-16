"""
    plot_section(x, y, z, levels=:auto;
        title="", xlab="Distance from Shore [km]",
        ylab="Pressure [db]", figure_size=(600, 400), font_size=8, show_stations=true)

Draw an oceanographic section plot, with contours for z=z(x,y). This is a
preliminary version of the function, subject to changes.  More documentation
will be added later, after a period of real-world testing and modification.
"""
function plot_section(x, y, z, levels=:auto;
    title="", xlab="Distance from Shore [km]",
    ylab="Pressure [db]", figure_size=(600, 400), font_size=8, show_stations=true)
    if levels == :auto
        levels = pretty(z, 10)
    end
    rval = contour(x, y, z, yflip=true, color=:black,
        xlab=xlab, ylab=ylab, title=title, titlelocation=:left,
        framestyle=:box, levels=levels, cbar=false, clabels=true,
        size=figure_size, tickdirection=:out,
        titlefontsize=font_size, labelfontsize=font_size, tickfontsize=font_size, dpi=dpi)
    if show_stations
        xlim, ylim = xlims(), ylims()
        for xx in x
            plot!(repeat([xx], 2), collect(ylim), xlim=xlim, ylim=ylim,
                seriestype=:path, color=:lightgray, linewidth=0.5, grid=false, label=false)
        end
    end
    rval
end
