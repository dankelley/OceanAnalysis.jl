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
    y = gsw_ct_freezing.(x, 0.0, 1.0)
    plot!(x, y, color=:darkgray, xlim=xlim, ylim=ylim; kwargs...)
end
export add_freezing_curve!



"""
    plot_TS(d::Union{Argo,Ctd}; sigma0_levels=[], spiciness0_levels=0,
        draw_freezing=true, abbreviate=false, fontsize::Integer=8,
        color_by=false, debug::Integer=0, kwargs...)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.

Whether contours of density and spiciness are drawn depends on values of the
`sigma0_levels` and `spiciness0_levels`. By default, a freezing-point line is
drawn (if it is within the range of the data) by calling
[`add_freezing_curve!`](@ref). If customization of line width, color, etc., is
required, uses `draw_freezing=false` and then call
[`add_freezing_curve!`](@ref) directly.

By default, axis names are written in long form; set `abbreviate=true` for
shorter versions.

Information about the analysis is printed if `debug` exceeds 0.

Apart from that, the other parameters have the usual meanings for Julia plots.
For example, `color` is set to black, to override the Julia default, etc.
In addition to those parameters, the `kwargs...` argument represents
any other argument that is accepted by `plot`.  This is illustrated
in the Examples.

Note that specifying `seriestype=:line` will yield a warning suggesting
to use `:path` instead.

# Arguments

- `d` either an Argo object or a Ctd object.

# Keywords

- `sigma0_levels` a specification of sigma0 values to be contoured. If this is
  an empty vector (which is the default) then the levels are selected
  automatically by providing [`pretty`](@ref) with values inferred from `ctd`. If
  `sigma0_levels` equals 0 then no contours are drawn.  If it is a positive
  integer, then it is taken as a suggestion for the number of levels.  And,
  finally, if it is a vector, then it is taken as a specification of the levels
  to be contoured. The work is done by a call to [`plot_TS_sigma0_contours`](@ref),
  so if customization (of contour line thickness, colour, etc), use
  `sigma0_levels=0` and then call [`plot_TS_sigma0_contours`](@ref) directly.

- `spiciness0_levels` as `sigma0_levels`, but for spiciness0 contours.
  The work is done by a call to [`plot_TS_spiciness0_contours`](@ref),
  so if customization (of contour line thickness, colour, etc), use
  `spiciness0_levels=0` and then call [`plot_TS_spiciness0_contours`(@ref)
  directly.

- `draw_freezing` a Bool indicating whether to draw a freezing-point curve.

- `abbreviate` a Bool indicating whether to abbreviate the axis labels.

- `fontsize` size of fonts to be supplied to [plot] as `tickfontsize`,
  `guidefontsize` and `titlefontsize`. Note that any of these values may also be
  supplied as named arguments within `kwargs...`.

- `color_by` a Tuple with 1 to 3 elements, used to set up for colorized points on
  the TS diagram, based on some variable that has the same length as
  `ctd.data.pressure`.  The first element of `color_by` is a vector of values for
  the variable to be represented by color. This is required. The second, if
  provided, indicates the color scheme (e.g. use `:inferno` or `:viridis` for
  popular alternatives to the rainbow-like `:turbo` default). And the third sets
  the limits of the color scale, which defaults to `extrema(x)`, if not provided.
  The Tuple is processed by [`decode_color_by`](@ref).

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
function plot_TS(d::Union{Argo,Ctd}; sigma0_levels=[], spiciness0_levels=0,
    draw_freezing=true, abbreviate=false, fontsize::Integer=8,
    color_by=false, debug::Integer=0, kwargs...)
    # This test might be useful if further customization is needed for a future version
    # of the package. For now, it simply makes for better debugging output.
    if isa(d, Argo)
        oad(debug, "plot_TS(::Argo) START")
    else
        oad(debug, "plot_TS(::Ctd) START")
    end
    oad(debug, "  sigma0_levels: $sigma0_levels")
    oad(debug, "  spiciness0_levels: $spiciness0_levels")
    oad(debug, "  draw_freezing: $draw_freezing")
    local S = d.data.salinity
    local T = d.data.temperature
    local p = d.data.pressure
    local lon = d.metadata["longitude"]
    local lat = d.metadata["latitude"]
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
    plot_TS_sigma0_contours(sigma0_levels; debug=increment_debug(debug))#, kwargs...)
    plot_TS_spiciness0_contours(spiciness0_levels; debug=increment_debug(debug))#, kwargs...)
    # Redraw the data, so they appear above other elements such as 
    # contours and the freezing-point line.
    plot!(SA, CT, legend=false, color=:black,
        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4;
        kwargs...)
    oad(debug, "END plot_TS()")
    rval
end # plot_TS()
export plot_TS



"""
    plot_TS_sigma0_contours(levels=[];
        color=:gray50, linewidth=1.19*default(:gridlinewidth),
        debug::Integer=0)

Add contours of density to an existing TS plot.  This is used by
[`plot_TS`](@ref), but can also be used separately, if the TS data
have been drawn by other means.

# Arguments

- `levels` a vector of the desired contour levels. There are three choices for
  this. (1) If this has zero length (which is the default) then levels are
  computed based on density, using `pretty()`, is used to compute levels based
  on the span of sigma0 in the existing plot. (2) If `levels` is a single
  integer, then again `pretty()` is used, but here with the second argument
  given as `levels`. (3) Otherwise, `levels` sets the contour levels directly.

# Keywords

- `color` the colour of the contours.

- `linewidth` the width of contour lines.

- `debug` an integer controlling the amount of information printed during
   processing.

"""
function plot_TS_sigma0_contours(levels=[];
        color=:gray50, linewidth=1.19*default(:gridlinewidth),
        debug::Integer=0)
    oad(debug, "plot_TS_sigma0_contours() START")
    oad(debug, "  levels: $levels")
    oad(debug, "  color: $(color)")
    oad(debug, "  linewidth: $(linewidth)")
    xlim = xlims()
    ylim = ylims()
    oad(debug, "  xlim: $xlim")
    oad(debug, "  ylim: $ylim")
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    sigma0c = gsw_sigma0.(SAc', CTc) |> fix_gsw_bad_code!
    oad(debug, "  SAc: $(extrema(SAc))")
    oad(debug, "  CTc: $(extrema(CTc))")
    oad(debug, "  sigma0c: $(extrema(sigma0c))")
    if length(levels) == 0
        oad(debug, "  case 1: levels is empty, so auto-compute sigma0 contour levels")
        levels = pretty(sigma0c) # returns [] if min=max
    elseif length(levels) == 1 && isa(levels, Integer)
        if levels > 0
            oad(debug, "  case 2a: auto-selecting $levels sigma0 levels to contour")
            levels = pretty(sigma0c, levels)
        else
            oad(debug, "  case 2b: will not contour sigma0 levels")
            levels = []
        end
    else
        oad(debug, "  case 3: levels is a vector of sigma0 levels for contouring")
    end
    if length(levels) > 0
        oad(debug, "  drawing sigma0 contours at levels $(levels)")
        contour!(SAc, CTc, sigma0c, xlim=xlim, ylim=ylim, levels=levels,
            linewidth=linewidth, color=color, cbar=false, clabels=true,
            foreground_color_axis=:black, foreground_color_border=:black)
    end
    oad(debug, "END plot_TS_sigma0_contours")
end
export plot_TS_sigma0_contours


"""
    plot_TS_spiciness0_contours(levels=[];
        color=:gray50, linewidth=1.19*default(:gridlinewidth),
        debug::Integer=0)

Add contours of spiciness0 to an existing TS plot.  This is used by
[`plot_TS`](@ref), but can also be used separately, if the TS data
have been drawn by other means.  For the meanings of the
arguments and keywords, see the documentation for
[`plot_TS_sigma0_contours`](@ref).
"""
function plot_TS_spiciness0_contours(levels=[];
        color=:gray50, linewidth=1.19*default(:gridlinewidth),
        debug::Integer=0)
    oad(debug, "plot_TS_spiciness0_contours() START")
    oad(debug, "  levels: $levels")
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    spiciness0c = gsw_spiciness0.(SAc', CTc) |> fix_gsw_bad_code!
    if length(levels) == 0
        oad(debug, "  case 1: spiciness0_levels is empty, so auto-compute spiciness0 contour levels")
        spiciness0_levels = pretty(spiciness0c) # returns [] if min=max
    elseif length(levels) == 1 && isa(levels, Integer)
        if levels > 0
            oad(debug, "  case 2a: auto-selecting $levels spiciness0 levels to contour")
            levels = pretty(spiciness0c, levels)
        else
            oad(debug, "  case 2b: will not contour spiciness0 levels")
            levels = []
        end
    else
        oad(debug, "  case 3: levels is a vector of spiciness0 levels for contouring")
    end
    if length(levels) > 0
        oad(debug, "  drawing spiciness0 contours at levels $(levels)")
        contour!(SAc, CTc, spiciness0c, xlim=xlim, ylim=ylim,
            linewidth=contour_linewidth, color=:gray50,
            levels=levels, cbar=false, clabels=true,
            foreground_color_axis=:black, foreground_color_border=:black)
    end
    oad(debug, "END plot_TS_spiciness0_contours")
end
export plot_TS_spiciness0_contours

