using GibbsSeaWater: gsw_ct_freezing, gsw_ct_from_t, gsw_sa_from_sp, gsw_sigma0, gsw_spiciness0

"""
    add_freezing_curve!(xlim, ylim; kwargs...)

Draw a freezing-point curve on an existing CT-SA plot. This is called by
[`plot_TS`](@ref), but can also be called by the user, if customization of line
type, etc, is required.
"""
function add_freezing_curve!(xlim, ylim; kwargs...)
    n = 50 # it is a pretty straight curve
    x = range(xlim[1], xlim[2], length=n)
    y = gsw_ct_freezing.(x, repeat([0.0], n), repeat([1.0], n))
    plot!(x, y, color=:darkgray, xlim=xlim, ylim=ylim; kwargs...)
end

"""
    plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
        draw_freezing=true, abbreviate=false, fontsize=8, debug::Integer=0, kwargs...)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.

Whether contours of density and spiciness are drawn depends on values of the
`sigma0_levels` and `spiciness0_level` arguments. The actual work of contouring
is carried out by calling [`plot_TS_sigma0_contours`](@ref) and
[`plot_TS_spiciness0_contours`](@ref), both of which can be called after
`plot_TS` completes its work, if desired. Depending on the values of
`sigma0_levels` and `spiciness0_levels`, there are 3 possibilities. (1) Setting
either to `[]` yields contours with automatic selection of levels. (2) Setting
either to a positive integer provides a suggestion for the number of levels,
with the actual number being set by [`pretty`](@ref)), which is provided with
the integer, and with `0` meaning not to show contours at all.  And, finally,
(3) Setting either to a vector of numbers specifies those numbers as the
levels.

By default, a freezing-point line is drawn (if it is within the range of the
data) by calling [`add_freezing_curve!`](@ref). If customization of line width,
colour, etc., is required, uses `draw_freezing=false` and then call
[`add_freezing_curve!`](@ref) directly.

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

- `sigma0_levels` a specification of sigma0 values to be contoured. If this is
  an empty vector (which is the default) then the levels are selected
  automatically by providing [`pretty`](@ref) with values inferred from `ctd`. If
  `sigma0_levels` equals 0 then no contours are drawn.  If it is a positive
  integer, then it is taken as a suggestion for the number of levels.  And,
  finally, if it is a vector, then it is taken as a specification of the levels
  to be contoured.

- `spiciness0_levels` as `sigma0_levels`, but for spiciness0 contours.

- `draw_freezing` a Bool indicating whether to draw a freezing-point curve.

- `abbreviate` a Bool indicating whether to abbreviate the axis labels.

- `fontsize` size of fonts to be supplied to [plot] as `tickfontsize`,
  `guidefontsize` and `titlefontsize`. Note that any of these values may also be
  supplied as named arguments within `kwargs...`.

- `debug` indicator of debugging level. If this exceeds 0, some information is
  printed during processing.

- `kwargs...` is passed to `plot()`, to permit further customization; see
   https://docs.juliaplots.org/stable/ for more information on possibilities.

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
    draw_freezing=true, abbreviate=false, fontsize=8, debug::Integer=0, kwargs...)
    oad(debug, "plot_TS(<ctd>) START")
    oad(debug, "  sigma0_levels: $sigma0_levels")
    oad(debug, "  spiciness0_levels: $spiciness0_levels")
    oad(debug, "  draw_freezing: $draw_freezing")
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
    # Draw the data.
    oad(debug, "  drawing data points")
    if haskey(kwargs, :seriestype) && kwargs[:seriestype] == :line
        @warn "It is a *very* bad idea to use seriestype=:line in TS plots; use :path instead"
    end
    rval = plot(SA, CT,
        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
        ylabel=abbreviate ? "CT [°C]" : "Conservative Temperature [°C]",
        yrot=90,
        framestyle=:box, legend=false, color=:black, tickdirection=:out,
        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4,
        tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize;
        kwargs...)
    # Possibly add freezing-point curve
    if draw_freezing
        add_freezing_curve!(xlims(), ylims())
    end
    # Possibly add density contours
    plot_TS_sigma0_contours(sigma0_levels; debug=increment_debug(debug), kwargs...)
    plot_TS_spiciness0_contours(spiciness0_levels; debug=increment_debug(debug), kwargs...)
    # Redraw the data, so they appear above other elements such as 
    # contours and the freezing-point line.
    plot!(SA, CT, legend=false, color=:black,
        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4;
        kwargs...)
    oad(debug, "END plot_TS()")
    rval
end # plot_TS()



"""
    plot_TS_sigma0_contours(sigma0_levels=[]; debug::Integer=0, kwargs...)

Add contours of density to an existing TS plot.  This is used by
[`plot_TS`](@ref), but can also be used separately, if the TS data
have been drawn by other means.  For the meanings of the
arguments, see the documentation for [`plot_TS`](@ref).
"""
function plot_TS_sigma0_contours(sigma0_levels=[]; debug::Integer=0, kwargs...)
    oad(debug, "plot_TS_sigma0_contours() START")
    oad(debug, "  sigma0_levels: $sigma0_levels")
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    sigma0c = gsw_sigma0.(SAc', CTc) |> fix_gsw_bad_code!
    if length(sigma0_levels) == 0
        oad(debug, "  case 1: sigma0_levels is empty, so auto-compute sigma0 contour levels")
        sigma0_levels = pretty(sigma0c) # returns [] if min=max
    elseif length(sigma0_levels) == 1 && isa(sigma0_levels, Integer)
        if sigma0_levels > 0
            oad(debug, "  case 2a: auto-selecting $sigma0_levels sigma0 levels to contour")
            sigma0_levels = pretty(sigma0c, sigma0_levels)
        else
            oad(debug, "  case 2b: will not contour sigma0 levels")
            sigma0_levels = []
        end
    else
        oad(debug, "  case 3: sigma0_levels is a vector of sigma0 levels for contouring")
    end
    # Set contour linewidth to 2^(1/4) times grid line width. This
    # corresponds the diameter step between Rapidography technical pens
    # at number category 0 to 00.
    contour_linewidth = 1.19 * default(:gridlinewidth) # factor is 2^(1/4)
    if length(sigma0_levels) > 0
        oad(debug, "  drawing sigma0 contours at levels $(sigma0_levels)")
        contour!(SAc, CTc, sigma0c, xlim=xlim, ylim=ylim, linewidth=contour_linewidth, color=:gray50, levels=sigma0_levels, cbar=false, clabels=true, foreground_color_axis=:black, foreground_color_border=:black; kwargs...)
    end
    oad(debug, "END plot_TS_sigma0_contours")
end

"""
    plot_TS_spiciness0_contours(spiciness0_levels=[]; debug::Integer=0, kwargs...)

Add contours of density to an existing TS plot.  This is used by
[`plot_TS`](@ref), but can also be used separately, if the TS data
have been drawn by other means.  For the meanings of the
arguments, see the documentation for [`plot_TS`](@ref).
"""
function plot_TS_spiciness0_contours(spiciness0_levels=[]; debug::Integer=0, kwargs...)
    oad(debug, "plot_TS_spiciness0_contours() START")
    oad(debug, "  spiciness0_levels: $spiciness0_levels")
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    spiciness0c = gsw_spiciness0.(SAc', CTc) |> fix_gsw_bad_code!
    if length(spiciness0_levels) == 0
        oad(debug, "  case 1: spiciness0_levels is empty, so auto-compute spiciness0 contour levels")
        spiciness0_levels = pretty(spiciness0c) # returns [] if min=max
    elseif length(spiciness0_levels) == 1 && isa(spiciness0_levels, Integer)
        if spiciness0_levels > 0
            oad(debug, "  case 2a: auto-selecting $spiciness0_levels spiciness0 levels to contour")
            spiciness0_levels = pretty(spiciness0c, spiciness0_levels)
        else
            oad(debug, "  case 2b: will not contour spiciness0 levels")
            spiciness0_levels = []
        end
    else
        oad(debug, "  case 3: spiciness0_levels is a vector of spiciness0 levels for contouring")
    end
    # Set contour linewidth to 2^(1/4) times grid line width. This
    # corresponds the diameter step between Rapidography technical pens
    # at number category 0 to 00.
    contour_linewidth = 1.19 * default(:gridlinewidth) # factor is 2^(1/4)
    if length(spiciness0_levels) > 0
        oad(debug, "  drawing spiciness0 contours at levels $(spiciness0_levels)")
        contour!(SAc, CTc, spiciness0c, xlim=xlim, ylim=ylim, linewidth=contour_linewidth, color=:gray50, levels=spiciness0_levels, cbar=false, clabels=true, foreground_color_axis=:black, foreground_color_border=:black; kwargs...)
    end
    oad(debug, "END plot_TS_spiciness0_contours")
end

