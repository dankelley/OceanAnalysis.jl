using GibbsSeaWater: gsw_ct_freezing, gsw_ct_from_t, gsw_sa_from_sp, gsw_sigma0, gsw_spiciness0

"""
    plot_freezing_curve!(xlim, ylim; kwargs...)

Draw a freezing-point curve on an existing CT-SA plot. This is called by
[`plot_TS`](@ref), but can also be called by the user, if customization of line
type, etc, is required.
"""
function plot_freezing_curve!(; kwargs...)
    n = 50 # it is a pretty straight curve
    xlim = xlims()
    ylim = ylims()
    SA = range(xlim[1], xlim[2], length=n)
    CT = gsw_ct_freezing.(SA, 0.0, 1.0) # SA, p, saturation_fraction
    plot!(SA, CT, label=false, color=:darkgray, xlim=xlim, ylim=ylim; kwargs...)
end
export plot_freezing_curve!



"""
    plot_TS(d; sigma0_levels=[], spiciness0_levels=0,
        plot_freezing=true, abbreviate=false, fontsize::Integer=8,
        color=:black, color_by=false, debug::Integer=0, kwargs...)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.

Whether contours of density and spiciness are drawn depends on values of the
`sigma0_levels` and `spiciness0_levels`. By default, a freezing-point line is
drawn (if it is within the range of the data) by calling
[`plot_freezing_curve!`](@ref). If customization of line width, color, etc., is
required, uses `plot_freezing=false` and then call
[`plot_freezing_curve!`](@ref) directly.

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

- `d` either an [`Argo`](@ref) object or a [`Ctd`](@ref) object.

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

- `plot_freezing` a Bool indicating whether to draw a freezing-point curve.

- `abbreviate` a Bool indicating whether to abbreviate the axis labels.

- `fontsize` size of fonts to be supplied to [plot] as `tickfontsize`,
  `guidefontsize` and `titlefontsize`. Note that any of these values may also be
  supplied as named arguments within `kwargs...`.

- `color` the colour to be used for lines and possibly markers. This
  is used for both if `color_by` (see next) is false. However, if
  `color_by` is a NamedTuple, then `color` only applies to the lines.

- `color_by` a control on whether points on the plot are to be colorized
  individually according to some specified value. Four choices are
  possible. (1) If `color_by=false`, then all the data points are painted
  with the same `color`. (2) If `color_by` is a string naming a column
  in `d.data`, then colors are selected to show variation of the named
  variable.  (3) If `color_by` is a NamedTuple as created by
  [`decode_color_by`](@ref), then the variable may be in `ctd.data`
  but it may also be a numeric vector of appropriate length. Furthermore,
  in this choice the user can set the colorscheme and the spacing
  between the main plot and the palette. (4) And, finally,
  if `color_by=""` then the points are not colorized, and no
  palette is drawn, but space set aside to the right of the plot,
  where a palette would otherwise go.

- `debug` indicator of debugging level. If this exceeds 0, some information is
  printed during processing.

- `kwargs...` is passed to `plot()`, to permit further customization; see
   https://docs.juliaplots.org/stable/ for more information on possibilities.

# Examples

```julia
using OceanAnalysis, Plots

# Get data for examples
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(f);

# Example 1: set title.
plot_TS(ctd, title="Built-in CTD file")

# Example 2: just symbols, with no line.
plot_TS(ctd, seriestype=:scatter)

# Example 3: just a line, with no symbols.
plot_TS(ctd, marker=:none)

# Example 4: color_by pressure.
# The markers are drawn without borders, to avoid black overpainting.
plot_TS(ctd, markerstrokewidth=0, markersize=3, color_by="pressure")

# Example 5: black/white plot, but with space where a palette would go.
plot_TS(ctd, color_by="")
```
"""
function plot_TS(d; sigma0_levels=[], spiciness0_levels=0,
    plot_freezing=true, abbreviate=false, fontsize::Integer=8,
    color=:black, color_by=false, debug::Integer=0, kwargs...)
    error("plot_TS() disabled, pending convertion from Plots to Makie")
    #<disabled>    # This test might be useful if further customization is needed for a future version
    #<disabled>    # of the package. For now, it simply makes for better debugging output.
    #<disabled>    if isa(d, Argo)
    #<disabled>        oad(debug, "plot_TS(::Argo) START")
    #<disabled>    elseif isa(d, Ctd)
    #<disabled>        oad(debug, "plot_TS(::Ctd) START")
    #<disabled>    else
    #<disabled>        error("plot_TS() only works on Argo and Ctd objects")
    #<disabled>    end
    #<disabled>    oad(debug, "  sigma0_levels: $sigma0_levels")
    #<disabled>    oad(debug, "  spiciness0_levels: $spiciness0_levels")
    #<disabled>    oad(debug, "  plot_freezing: $plot_freezing")
    #<disabled>    local S = d.data.salinity
    #<disabled>    local T = d.data.temperature
    #<disabled>    local p = d.data.pressure
    #<disabled>    local lon = d.metadata["longitude"]
    #<disabled>    local lat = d.metadata["latitude"]
    #<disabled>    SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    #<disabled>    CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
    #<disabled>    ok = isfinite.(SA) .& isfinite.(CT)
    #<disabled>    if 0 == sum(ok)
    #<disabled>        @warn "plot_TS(): no good SA,CT pairs, so plotting an aphysical default"
    #<disabled>    end
    #<disabled>    # Draw the data.
    #<disabled>    oad(debug, "  drawing data points")
    #<disabled>    if haskey(kwargs, :seriestype) && kwargs[:seriestype] == :line
    #<disabled>        @warn "It is a *very* bad idea to use seriestype=:line in TS plots; use :path instead"
    #<disabled>    end
    #<disabled>    using_color_by = false
    #<disabled>    if color_by != false
    #<disabled>        if isa(color_by, String)
    #<disabled>            oad(debug, "  color_by: \"", color_by, "\"")
    #<disabled>            if color_by in names(d.data)
    #<disabled>                color_by = decode_color_by(d[color_by])
    #<disabled>                oad(debug, "  decoded palette details with decode_color_by()")
    #<disabled>            elseif color_by == ""
    #<disabled>                oad(debug, "  no palette will be drawn, since color_by=\"\"")
    #<disabled>            else
    #<disabled>                error("color_by is \"", color_by, "\" which is neither \"\" nor in names(d.data)")
    #<disabled>            end
    #<disabled>        elseif isa(color_by, NamedTuple)
    #<disabled>            if length(color_by.levels) != nrow(d.data)
    #<disabled>                error("length(color_by.levels)=", length(color_by.levels), " ≠ nrow(d.data)=", nrow(d.data))
    #<disabled>            end
    #<disabled>        else
    #<disabled>            error("color_by must be 'false', a String, or a NamedTuple")
    #<disabled>        end
    #<disabled>        using_color_by = true
    #<disabled>    end
    #<disabled>    p_TS = plot(SA, CT,
    #<disabled>        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
    #<disabled>        ylabel=abbreviate ? "CT [°C]" : "Conservative Temperature [°C]",
    #<disabled>        yrot=90,
    #<disabled>        framestyle=:box, legend=false, color=color, tickdirection=:out,
    #<disabled>        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4,
    #<disabled>        tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize;
    #<disabled>        kwargs...)
    #<disabled>    # Possibly add freezing-point curve
    #<disabled>    if plot_freezing
    #<disabled>        plot_freezing_curve!()
    #<disabled>    end
    #<disabled>    # Possibly add density contours
    #<disabled>    plot_TS_sigma0_contours(sigma0_levels; debug=debug)
    #<disabled>    plot_TS_spiciness0_contours(spiciness0_levels; debug=debug)
    #<disabled>    # Redraw the data, so they appear above other elements such as 
    #<disabled>    # contours and the freezing-point line. Note that the path will be
    #<disabled>    # drawn with the provided the 'color'.
    #<disabled>    if using_color_by
    #<disabled>        if color_by == ""
    #<disabled>            oad(debug, "  not plotting symbols with individual colours, but leaving palette space")
    #<disabled>            p_cbar = plot(ticks=nothing, border=:none)
    #<disabled>            l = grid(1, 2, widths=[0.88, 0.12])
    #<disabled>            p_TS = plot(p_TS, p_cbar, layout=l)
    #<disabled>        else
    #<disabled>            oad(debug, "  plotting symbols with individual colours")
    #<disabled>            cindex = (color_by.levels .- color_by.clims[1]) / (color_by.clims[2] - color_by.clims[1])
    #<disabled>            colormap = cgrad(color_by.colorscheme)
    #<disabled>            markercolor = colormap[cindex]
    #<disabled>            plot!(SA, CT, seriestype=:scatter,
    #<disabled>                legend=false, linecolor=color, markercolor=markercolor,
    #<disabled>                linewidth=1.0, marker=:circle, markersize=1.4;
    #<disabled>                kwargs...)
    #<disabled>            p_cbar = scatter([1], [NaN], zcolor=[color_by.clims[1]], colormap=colormap, clims=color_by.clims, cbar=true, ticks=false, framestyle=:none, label="")
    #<disabled>            l = grid(1, 2, widths=[0.88, 0.12])
    #<disabled>            p_TS = plot(p_TS, p_cbar, layout=l)
    #<disabled>        end
    #<disabled>    end
    #<disabled>    oad(debug, "END plot_TS()")
    #<disabled>    return p_TS
end
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
    color=:gray50, linewidth=1.19 * default(:gridlinewidth),
    debug::Integer=0)
    oad(debug, "plot_TS_sigma0_contours() START")
    oad(debug, "  levels: ", levels)
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    sigma0c = gsw_sigma0.(SAc', CTc) |> fix_gsw_bad_code!
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
    color=:gray50, linewidth=1.19 * default(:gridlinewidth),
    debug::Integer=0)
    oad(debug, "plot_TS_spiciness0_contours() START")
    oad(debug, "  levels: ", levels)
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

