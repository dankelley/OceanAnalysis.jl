"""
    plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
        draw_freezing=true, abbreviate=false, fontsize=8, debug::Int64=0, kwargs...)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.

Whether contours of density and spiciness are drawn depends on values of the
`sigma0_levels` and `spiciness0_level` arguments. There are 4 categories. (1)
Setting either to 0 prevents contouring. (2) Setting either to `[]` enables
contours with automatic selection of levels. (3) Setting either to a positive
integer provides a suggestion for the number of levels, with the actual number
being set by [`pretty`](@ref)), which is provided with the integer.  (4)
Setting either to a vector of numbers specifies those numbers as the levels.

By default, a freezing-point line is drawn (if it is within the range of the
data). This behaviour is skipped if `draw_freezing` is false.

By default, axis names are written in long form; set `abbreviate=true` for
shorter versions.

Information about the analysis is printed if `debug` is set to true.

Apart from that, the other parameters have the usual meanings for Julia plots.
For example, `color` is set to black, to override the Julia default, etc.
In addition to those parameters, the `kwargs...` argument represents
any other argument that is accepted by `plot`.  This is illustrated
in the Examples.

Note that specifying `seriestype=:line` will yield a warning suggesting
to use `:path` instead.

# Arguments

- `ctd` a Ctd value for which a temperature-salinity diagram will be plotted.

# Keywords

- `sigma0_levels` a specification of sigma0 values to be contour. If this is an empty vector (which is the default) then the levels are selected automatically by providing [`pretty`](@ref) with values inferred from `ctd`. If `sigma0_levels` equals 0 then no contours are drawn.  If it is a positive integer, then it is taken as a suggestion for the number of levels.  And, finally, if it is a vector, then it is taken as a specification of the levels to be contoured.

- `sigma0_levels` as `sigma0_levels`, but for spiciness0 contours.

- `draw_freezing` a Bool indicating whether to draw a freezing-point curve.

- `abbreviate` a Bool indicating whether to abbreviate the axis labels,.

- `fontsize` size of fonts to be supplied to [plot] as `tickfontsize`, `guidefontsize` and `titlefontsize`. Note that any of these values may also be supplied as named arguments within `kwargs...`.

- `debug` indicator of debugging level. If this exceeds 0, some information is printed during processing.

- `kwargs...` is passed to `plot()`, to permit further customization; see https://docs.juliaplots.org/stable/ for more information on possibilities.

```julia
using OceanAnalysis, Plots, Dates
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(f);
# Example 1: set title
plot_TS(ctd, title="Built-in CTD file")
# Example 2: just symbols, with no line
plot_TS(ctd, seriestype=:scatter)
# Example 3: just a line, with no symbols
plot_TS(ctd, marker=:none)
```

See also [`plot_profile`](@ref).
"""
function plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
    draw_freezing=true, abbreviate=false, fontsize=8, debug::Int64=0, kwargs...)
    oad(debug, "plot_TS(<ctd>) START")
    local S = ctd.data.salinity
    local T = ctd.data.temperature
    local p = ctd.data.pressure
    local lon = ctd.metadata["longitude"]
    local lat = ctd.metadata["latitude"]
    SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
    ok = isfinite.(SA) .& isfinite.(CT)
    if 0 == sum(ok)
        @warn "plot_TS(): no good SA,CT pairs, so plotting an aphysical default"
    end
    # We start with the measurements ... 
    oad(debug, "    drawing data points")
    #oad(debug, "    kwargs... ", kwargs...)
    if haskey(kwargs, :seriestype) && kwargs[:seriestype] == :line
        @warn "It is a *very* bad idea to use seriestype=:line in TS plots; use :path instead"
    end
    # Draw the data. We will redraw the points/lines at the end, if
    # there are density or spiciness contours that would otherwise
    # be drawn on top.
    rval = plot(SA, CT,
        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
        ylabel=abbreviate ? "CT [°C]" : "Conservative Temperature [°C]",
        yrot=90,
        framestyle=:box, legend=false, color=:black, tickdirection=:out,
        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4,
        tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize;
        kwargs...)

    need_redraw = false # will set to true if we contour the data
    # Possibly add density contours
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    oad(debug, "    processing sigma0 contours")
    sigma0c = gsw_sigma0.(SAc', CTc) |> fix_gsw_bad_code!
    local levels = sigma0_levels
    if length(sigma0_levels) == 0
        oad(debug, "        case 1: sigma0_levels is empty, so auto-compute sigma0 contour levels")
        levels = pretty(sigma0c) # returns [] if min=max
    elseif length(sigma0_levels) == 1 && typeof(sigma0_levels) == Int64
        if sigma0_levels > 0
            oad(debug, "        case 2a: auto-selecting $sigma0_levels sigma0 levels to contour")
            levels = pretty(sigma0c, sigma0_levels)
        else
            oad(debug, "        case 2b: will not contour sigma0 levels")
            levels = []
        end
    else
        oad(debug, "        case 3: sigma0_levels is a vector of sigma0 levels for contouring")
    end
    # Set contour linewidth to 2^(1/4) times grid line width. This
    # corresponds the diameter step between Rapidography technical pens
    # at number category 0 to 00.
    contour_linewidth = 1.19 * default(:gridlinewidth) # factor is 2^(1/4)
    if length(levels) > 0
        oad(debug, "        drawing sigma0 contours at levels $(levels)")
        contour!(SAc, CTc, sigma0c, linewidth=contour_linewidth, color=:gray50, levels=levels, cbar=false, clabels=true, foreground_color_axis=:black, foreground_color_border=:black)
        need_redraw = true
    else
        oad(debug, "        not drawing sigma0 contours")
    end
    # ... then (optionally) add spiciness contours ...
    oad(debug, "    processing spiciness0 contours")
    spiciness0c = gsw_spiciness0.(SAc', CTc) |> fix_gsw_bad_code!
    local levels = spiciness0_levels
    if length(spiciness0_levels) == 0
        oad(debug, "        case 1: spiciness0_levels is empty, so auto-compute spiciness0 contour levels")
        levels = pretty(spiciness0c)
    elseif length(spiciness0_levels) == 1 && typeof(spiciness0_levels) == Int64
        oad(debug, "        case 2: spiciness0_levels is a single integer ($spiciness0_levels)")
        if spiciness0_levels > 0
            levels = pretty(spiciness0c, spiciness0_levels)
        else
            levels = []
        end
    else
        oad(debug, "        case 3: spiciness0_levels is a vector of spiciness0 levels for contouring")
    end
    if length(levels) > 0
        oad(debug, "    drawing spiciness0 contours at levels $(levels)")
        contour!(SAc, CTc, spiciness0c, linewidth=contour_linewidth, color=:gray50, levels=levels,
            cbar=false, clabels=true, foreground_color_text=:black)
        need_redraw = true
    else
        oad(debug, "        not drawing spiciness0 contours")
    end
    # ... and finally (optionally) add a freezing-temperature line.
    if draw_freezing
        oad(debug, "    adding freezing line")
        pf = 0.0 # let user specify this?
        SAf = range(xlim[1], xlim[2], length=100)
        saturation_fraction = 0.0
        CTf = gsw_ct_freezing.(SAf, pf, saturation_fraction)
        plot!(xlim=xlim, ylim=ylim)
        plot!(SAf, CTf, linewidth=0.75, color=:black, linestyle=:dash)
    end
    # Redraw the data, if we contours of density or spiciness have been drawn.
    # This avoids obscuring the data, and is in keeping with how Julia plots
    # gridlines under the data.
    if need_redraw
        plot!(SA, CT, legend=false, color=:black,
            seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4;
            kwargs...)
    end
    oad(debug, "END plot_TS()")
    rval
end # plot_TS()



