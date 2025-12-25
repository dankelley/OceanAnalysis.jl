"""
    plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
        draw_freezing=true, abbreviate=false,
        framestyle=:box, color=:black, seriestype=:scatter, markersize=2.0, linewidth=1.0,
        legend=false, gridstyle=:dash, tickfontsize=8, tickdirection=:out,
        guidefontsize=8, debug::Int64=0, kwargs...)

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
in the example, which a title is added to the plot for a built-in
CNV-formatted CTD file.

Note that specifying `seriestype=:line` will yield a warning, and the
value will be changed to `:path` for the plot.


```julia
using OceanAnalysis, Plots, Dates
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(f);
plot_TS(ctd, title="Built-in CTD file", titlefontsize=9)
```

See also [`plot_profile`](@ref).
"""
function plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
    draw_freezing=true, abbreviate=false,
    framestyle=:box, color=:black, seriestype=:scatter, markersize=2.0, linewidth=1.0,
    legend=false, gridstyle=:dash, tickfontsize=8, tickdirection=:out,
    guidefontsize=8, debug::Int64=0, kwargs...)
    oad(debug, "plot_TS(<ctd>) START")
    local S = ctd.data.salinity
    local T = ctd.data.temperature
    local p = ctd.data.pressure
    local lon = ctd.metadata["longitude"]
    local lat = ctd.metadata["latitude"]
    SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
    # We start with the measurements ... 
    oad(debug, "    drawing data")
    oad(debug, "    kwargs... ", kwargs...)
    if seriestype == :line
        @warn "plot_TS() switching seriestype from :line to :path"
        seriestype = :path
    end
    rval = plot(SA, CT, legend=legend,
        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
        ylabel=abbreviate ? "C [°C]" : "Conservative Temperature [°C]",
        yrot=90, framestyle=framestyle,
        seriestype=seriestype, linewidth=linewidth, markersize=markersize,
        gridstyle=gridstyle, color=color,
        tickfontsize=tickfontsize, tickdirection=tickdirection,
        guidefontsize=guidefontsize; kwargs...)
    # ... then add density contours ...
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
        oad(debug, "        case 2: sigma0_levels is a single integer")
        if sigma0_levels > 0
            levels = pretty(sigma0c, sigma0_levels)
        else
            levels = []
        end
    else
        oad(debug, "        case 3: sigma0_levels is a vector of sigma0 levels for contouring")
    end
    if length(levels) > 0
        oad(debug, "        drawing sigma0 contours at levels $(levels)")
        contour!(SAc, CTc, sigma0c, color=:gray50, levels=levels,
            cbar=false, clabels=true, linewidth=linewidth)
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
        oad(debug, "        case 2: spiciness0_levels is a single integer")
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
        contour!(SAc, CTc, spiciness0c, color=:gray50, linewidth=1.0, levels=levels,
            cbar=false, clabels=true)
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
    oad(debug, "END plot_TS()")
    rval
end # plot_TS()

