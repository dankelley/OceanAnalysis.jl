using GibbsSeaWater: gsw_ct_freezing, gsw_ct_from_t, gsw_sa_from_sp, gsw_sigma0, gsw_spiciness0
"""
    plot_freezing_curve!(ax; color=:darkgray, linewidth=1, n=50, debug=0)

Draw a freezing-point curve on an existing CT-SA plot. This is called by
[`plot_TS`](@ref), but can also be called by the user, if customization of line
color and width is required.
"""
function plot_freezing_curve!(ax; color=:darkgray, linewidth=1.8, n=50, debug=0)
    oad(debug, "plot_freezing_curve!() START")
    axlims = ax.finallimits[]
    SAmin = minimum(axlims)[1]
    SAmax = maximum(axlims)[1]
    oad(debug, "    SAmin=$SAmin, SAmax=$SAmax")
    SA = range(SAmin, SAmax, length=n)
    CT = gsw_ct_freezing.(SA, 0.0, 1.0) # SA, p, saturation_fraction
    lines!(ax, SA, CT, color=color, linewidth=linewidth)
    oad(debug, "END plot_freezing_curve!()")
end
export plot_freezing_curve!


"""
    plot_TS(d; sigma0_levels=[], spiciness0_levels=0,
        plot_freezing=true, abbreviate=false,
        color_by=false, debug::Integer=0, kwargs...)

    plot_TS!(fig_pos, d; sigma0_levels=[], spiciness0_levels=0,
        plot_freezing=true, abbreviate=false,
        color_by=false, debug::Integer=0, kwargs...)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.

Whether contours of density and spiciness are drawn depends on values of the
`sigma0_levels` and `spiciness0_levels`. By default, a freezing-point line is
drawn (if it is within the range of the data) by calling
[`plot_freezing_curve!`](@ref), but if customization is required,
use `plot_freezing=false` and call [`plot_freezing_curve!`](@ref) directly.

By default, axis names are written in long form; set `abbreviate=true` for
shorter versions.

Information about the analysis is printed if `debug` exceeds 0.

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

- `kwargs...` extra arguments that are parsed and handled accordingly. If
  `seriestype` is supplied, it controls how the data are indicated.  Possible
  values are `:scatter` (the default), `:lines` and `:scatterlines`. Each of
  these is handled in a different way, and may be customized by specifying other
  `kwargs...` entries. As with other functions in the package, you may use
  `fontsize` to set the sizes of text being displayed. To see the possible
  elements provided withing `kwargs`, call this function
  with `debug=1` and it will display the entries (and values) that it
  is using.

# Return value

`plot_TS` returns a `Makie.Figure`, which can be displayed directly or
saved with `save("filename.png", fig)`.

The `plot_TS` form returns a `Makie.Figure`, which can be displayed
directly or saved with `save("filename.png", fig)`.

The `plot_TS!` form returns a NamedTuple containing `ax` (a `Makie.Axis`),
`plt` (a Makie `Lines`, `Scatter` or `Scatterlines` object) and `cb` (a
`Colorbar` object if `color_by` is a String, or `nothing` if `color_by=false` or
`color_by=""`).


# Examples

```julia
using OceanAnalysis, GLMakie # or CairoMakie
ctd = joinpath(pkgdir(OceanAnalysis), "data", "D4902911_095.nc") |> read_argo |> as_ctd;

# Non-mutating cases (single panel each)
plot_TS(ctd)
plot_TS(ctd; seriestype=:scatter, markersize=6)
plot_TS(ctd; seriestype=:scatter, markersize=6,
    colormap=:inferno, color_by="pressure")
plot_TS(ctd; seriestype=:scatterlines, markersize=6,
    color=:magenta, linewidth=2, colormap=:inferno, color_by="pressure")

# mutating cases (two panels)
fig = Figure()
figa = plot_TS!(fig[1, 1], ctd; seriestype=:scatter, markersize=6, colormap=:inferno, color_by="pressure", debug=0)
figb = plot_TS!(fig[2, 1], ctd; seriestype=:scatter, markersize=6, colormap=:inferno, color_by="", debug=1)
```
"""
function plot_TS(d; sigma0_levels=[], spiciness0_levels=0,
    plot_freezing=true, abbreviate=false,
    color_by=false, debug::Integer=0, kwargs...)
    oad(debug, "plot_TS() START")
    fig = Figure()
    ax = Axis(fig[1, 1])
    #plot_TS!(fig[1, 1], d; sigma0_levels=sigma0_levels, spiciness0_levels=spiciness0_levels,
    plt = plot_TS!(ax, d; sigma0_levels=sigma0_levels, spiciness0_levels=spiciness0_levels,
        plot_freezing=plot_freezing, abbreviate=abbreviate,
        color_by=color_by, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_TS()")
    return (ax=ax, fig=fig, plt=plt)
end
export plot_TS


function plot_TS!(fig_pos, d; sigma0_levels=[], spiciness0_levels=0,
    plot_freezing=true, abbreviate=false,
    color_by=false, debug::Integer=0, kwargs...)
    # This test might be useful if further customization is needed for a future version
    # of the package. For now, it simply makes for better debugging output.
    if isa(d, Argo)
        oad(debug, "plot_TS!(::Argo) START")
    elseif isa(d, Ctd)
        oad(debug, "plot_TS!(::Ctd) START")
    else
        error("plot_TS!() only works on Argo and Ctd objects")
    end
    oad(debug, "    sigma0_levels: $sigma0_levels")
    oad(debug, "    spiciness0_levels: $spiciness0_levels")
    oad(debug, "    plot_freezing: $plot_freezing")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    oad(debug, "    keys in kwargs_dict: $(collect(keys(kwargs_dict)))")
    color = pop!(kwargs_dict, :color, :black)
    oad(debug, "    color=$(oad_val(color)) (can be set within kwargs...)")
    colormap = pop!(kwargs_dict, :colormap, :turbo)
    oad(debug, "    colormap=$(oad_val(colormap)) (can be set within kwargs...)")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "    fontsize=$fontsize (can be set within kwargs...)")
    linewidth = pop!(kwargs_dict, :linewidth, 1.0)
    oad(debug, "    linewidth=$linewidth (can be set within kwargs...)")
    marker = pop!(kwargs_dict, :marker, :circle)
    oad(debug, "    marker=$marker (can be set within kwargs...)")
    markercolor = pop!(kwargs_dict, :markercolor, :black)
    oad(debug, "    markercolor=$(oad_val(markercolor)) (can be set within kwargs...)")
    markersize = pop!(kwargs_dict, :markersize, 5.0)
    oad(debug, "    markersize=$markersize (can be set within kwargs...)")
    seriestype = pop!(kwargs_dict, :seriestype, :scatterlines)
    oad(debug, "    seriestype=$seriestype (can be set within kwargs...)")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "    title=$title (can be set within kwargs...)")
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: color, colormap, fontsize, linewidth, ",
            "marker, markercolor, markersize, seriestype, and title")
    end
    local S = d.data.salinity
    local T = d.data.temperature
    local p = d.data.pressure
    local lon = d.metadata["longitude"]
    local lat = d.metadata["latitude"]
    SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
    ok = isfinite.(SA) .& isfinite.(CT)
    if 0 == sum(ok)
        @warn "plot_TS!(): no good SA,CT pairs, so plotting an aphysical default"
    end
    # Draw the data.
    oad(debug, "    drawing the data")
    using_color_by = false
    if color_by !== false
        if isa(color_by, String)
            oad(debug, "    color_by: \"", color_by, "\"")
            if color_by in names(d.data)
                color_by = decode_color_by(d[color_by])
                cindex = (color_by.levels .- color_by.clims[1]) / (color_by.clims[2] - color_by.clims[1])
                colormap = cgrad(color_by.colorscheme)
                markercolor = colormap[cindex]
                oad(debug, "    set markercolor based on color_by")
            elseif color_by == ""
                oad(debug, "    no palette will be drawn, since color_by=\"\"")
            else
                error("color_by is \"", color_by, "\" which is neither \"\" nor in names(d.data)")
            end
        elseif isa(color_by, NamedTuple)
            if length(color_by.levels) != nrow(d.data)
                error("length(color_by.levels)=", length(color_by.levels), " ≠ nrow(d.data)=", nrow(d.data))
            end
        else
            error("color_by must be 'false', a String, or a NamedTuple")
        end
        using_color_by = true
    end
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    xlabel = abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]"
    ylabel = abbreviate ? "CT [°C]" : "Conservative Temperature [°C]"
    ax = Axis(fig_pos[1, 1],
        title=title,
        xlabel=xlabel,
        ylabel=ylabel,
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    lims = pop!(kwargs_dict, :limits,
        (extend_extrema(skipmissing(SA))...,
            extend_extrema(skipmissing(CT))...))
    oad(debug, "    limits: $lims")
    limits!(ax, lims...)
    seriestype in (:lines, :scatter, :scatterlines) || error("seriestype=$(repr(seriestype)) unknown; try :line, :scatter or :scatterline")
    if seriestype == :lines
        oad(debug, "    calling lines!() with extra arguments as follows")
        oad(debug, "      • color:       $(oad_val(color))")
        oad(debug, "      • linewidth:   $(oad_val(linewidth))")
        plt = lines!(ax, SA, CT, color=color, linewidth=linewidth)
    elseif seriestype == :scatter
        oad(debug, "    calling scatter!() with extra arguments as follows")
        if using_color_by
            oad(debug, "      • color:       $(oad_val(markercolor)) ... may be controlled by color_by")
            oad(debug, "      • marker:      $(oad_val(marker))")
            oad(debug, "      • markersize:  $(oad_val(markersize))")
        else
            oad(debug, "      • marker:      $(oad_val(marker))")
            oad(debug, "      • markercolor: $(oad_val(markercolor))")
            oad(debug, "      • markersize:  $(oad_val(markersize))")
        end
        plt = scatter!(ax, SA, CT, color=markercolor, marker=marker, markersize=markersize)
    elseif seriestype == :scatterlines
        oad(debug, "    calling scatterlines!() with extra arguments as follows")
        oad(debug, "      • color:       $(oad_val(color))")
        oad(debug, "      • linewidth:   $(oad_val(linewidth))")
        oad(debug, "      • marker:      $(oad_val(marker))")
        oad(debug, "      • markercolor: $(oad_val(markercolor))")
        oad(debug, "      • markersize:  $(oad_val(markersize))")
        plt = scatterlines!(ax, SA, CT, color=color, linewidth=linewidth,
            marker=marker, markercolor=markercolor, markersize=markersize)
    else
        error("seriestype=$seriestype not permitted; try :lines, :scatter or :scatterlines")
    end
    if plot_freezing
        plot_freezing_curve!(ax; debug=increment_debug(debug))
    end
    plot_TS_sigma0_contours!(ax; levels=sigma0_levels, debug=increment_debug(debug))
    plot_TS_spiciness0_contours!(ax; levels=spiciness0_levels, debug=increment_debug(debug))
    cb = nothing
    if using_color_by
        if color_by != ""
            oad(debug, "    drawing colorbar")
            cb = Colorbar(fig_pos[1, 2], colormap=colormap, limits=color_by.clims, ticklabelsize=fontsize)
        else
            oad(debug, "    drawing whitespace at colorbar position")
            cb = Colorbar(fig_pos[1, 2], colormap=:inferno, limits=(0, 1), ticklabelsize=fontsize)
            cb.ticksvisible = false
            cb.ticklabelsvisible = false
            cb.labelvisible = false
            cb.spinewidth = 0
            cb.colormap = to_colormap([RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0)])
        end
    end
    oad(debug, "END plot_TS!()")
    return (ax=ax, plt=plt, cb=cb)
end
export plot_TS!



"""
    plot_TS_sigma0_contours!(ax; levels=[],
        color=:gray75, linewidth=2.0, debug::Integer=0)

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
function plot_TS_sigma0_contours!(ax; levels=[],
    color=:gray75, alpha=0.5, linewidth=2.0, linestyle=:solid, debug::Integer=0)
    oad(debug, "plot_TS_sigma0_contours!() START")
    oad(debug, "  levels: ", levels)
    if levels == 0
        oad(debug, "    not contouring, since levels=0")
        oad(debug, "END plot_TS_sigma_contours!()")
        return
    end
    axlims = ax.finallimits[]
    SAmin = minimum(axlims)[1]
    SAmax = maximum(axlims)[1]
    CTmin = minimum(axlims)[2]
    CTmax = maximum(axlims)[2]
    oad(debug, "    SAmin=$SAmin, SAmax=$SAmax")
    oad(debug, "    CTmin=$CTmin, CTmax=$CTmax")
    SAc = range(SAmin, SAmax, length=300)
    CTc = range(CTmin, CTmax, length=300)
    sigma0c = gsw_sigma0.(SAc, CTc') |> fix_gsw_bad_code!
    if length(levels) == 0
        oad(debug, "    case 1: levels is empty, so auto-select contour levels")
        levels = pretty(sigma0c) # returns [] if min=max
    elseif length(levels) == 1 && isa(levels, Integer)
        oad(debug, "    case 2: auto-selecting $levels sigma0 levels to contour")
        levels = pretty(sigma0c, levels)
    else
        oad(debug, "    case 3: levels is a vector of sigma0 values to be contoured")
    end
    if length(levels) > 0
        oad(debug, "    contouring sigma0")
        contour!(ax, SAc, CTc, sigma0c, levels=levels, labels=true,
            linewidth=linewidth, linestyle=linestyle, color=color, alpha=alpha)
    end
    oad(debug, "END plot_TS_sigma0_contours!()")
end


"""
    plot_TS_spiciness0_contours!(ax; levels=[],
        color=:gray75, linewidth=2.0, debug::Integer=0)

Add contours of spiciness0 to an existing TS plot.  This is used by
[`plot_TS`](@ref), but can also be used separately, if the TS data
have been drawn by other means.  For the meanings of the
arguments and keywords, see the documentation for
[`plot_TS_sigma0_contours`](@ref).
"""
function plot_TS_spiciness0_contours!(ax; levels=[],
    color=:gray75, alpha=0.5, linewidth=2.0, linestyle=(:dot, :dense), debug::Integer=0)
    oad(debug, "plot_TS_spiciness0_contours!() START")
    oad(debug, "    levels: ", levels)
    if levels == 0
        oad(debug, "    not contouring, since levels=0")
        oad(debug, "END plot_TS_sigma0_contours!()")
        return
    end
    axlims = ax.finallimits[]
    SAmin = minimum(axlims)[1]
    SAmax = maximum(axlims)[1]
    CTmin = minimum(axlims)[2]
    CTmax = maximum(axlims)[2]
    oad(debug, "    SAmin=$SAmin, SAmax=$SAmax")
    oad(debug, "    CTmin=$CTmin, CTmax=$CTmax")
    SAc = range(SAmin, SAmax, length=100)
    CTc = range(CTmin, CTmax, length=300)
    spiciness0c = gsw_spiciness0.(SAc, CTc') |> fix_gsw_bad_code!
    if length(levels) == 0
        oad(debug, "  case 1: levels is empty, so auto-select contour levels")
        levels = pretty(spiciness0c) # returns [] if min=max
    elseif length(levels) == 1 && isa(levels, Integer)
        oad(debug, "  case 2: auto-selecting $levels spiciness0 levels to contour")
        levels = pretty(spiciness0c, levels)
    else
        oad(debug, "  case 3: levels is a vector of spiciness0 values to be contoured")
    end
    if length(levels) > 0
        oad(debug, "    contouring spiciness0")
        contour!(ax, SAc, CTc, spiciness0c, levels=levels, labels=true,
            linewidth=linewidth, linestyle=linestyle, color=color, alpha=alpha)
    end
    oad(debug, "END plot_TS_spiciness0_contours!()")
end
export plot_TS_spiciness0_contours!

