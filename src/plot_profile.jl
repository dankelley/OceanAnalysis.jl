"""
    plot_profile(d; which::String="CT", vertical::Symbol=:pressure,
        abbreviate::Symbol=:long, fontsize=8, color=:black, color_by=false,
        debug::Integer=0, kwargs...)

Plot an oceanographic profile for data contained in `d`, showing how the
variable named by `which` depends on either pressure or density.  The variable
is drawn on the x axis and either sigma0 or pressure on the y axis; in both
cases, the waters nearer the surface are shown nearer the top of the plot.

# Arguments

- `d` either an Argo object or a Ctd object.

# Keywords

- `which` an indication of what to plot on the x axis. The default value,
  `"CT"`, indicates to plot Conservative Temperature. Anything stored in the
  object's `data` can be plotted, along with some things that can be calculated
  from these values. Common choices include: `"N2"` for N², the square of the
  buoyancy frequency; `"SA"` for the Gibbs Seawater formulation of Absolute
  Salinity; `"salinity"` for Practical Salinity; `"sigma0"` for the Gibbs
  Seawater formulation of density anomaly referenced to the surface;
  `"spiciness0"` for the Gibbs Seawater seawater spiciness referenced to the
  surface; and `"temperature"` for in-situ temperature.

- `vertical` a Symbol specifying what to plot on the y axis. The default is
  `:pressure`, but `:density` is also permitted.

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

- `abbreviate` a Symbol indicating a category for axis length, used in
  determining how to label the axes. The valid choices are `:short`, `:medium`,
  and `:long`.

- `fontsize` size of fonts to be supplied to [plot] as `tickfontsize`,
  `guidefontsize` and `titlefontsize`. Note that any of these values may also be
  supplied as named arguments within `kwargs...`.

- `debug` indicator of debugging level. If this exceeds 0, some information is
  printed during processing.

- `kwargs...` is passed to `plot()`, to permit further customization; see
  https://docs.juliaplots.org/stable/ for more information on possibilities.

# Return value
`plot_profile` returns a `Makie.Figure`, which can be displayed directly or
saved with `save("filename.png", fig)`.

# Examples
```julia
using OceanAnalysis, Plots

# Get data used in examples.
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
ctd = read_argo(f) |> as_ctd;

# Example 1: overview of an Argo profile.
# Plot profiles of Conservative Temperature, Absolute Salinity, and potential
# density anomaly with respect to surface pressure.
p1 = plot_profile(ctd; which="CT")
p2 = plot_profile(ctd; which="SA")
p3 = plot_profile(ctd; which="sigma0")
plot(p1, p2, p3, layout=(1, 3), size=(800, 400))

# Example 2: add a new variable to the profile, then plot it.
using GibbsSeaWater
ctd.data.conductivity = gsw_c_from_sp.(ctd["salinity"], ctd["temperature"], ctd["pressure"]);
plot_profile(ctd, which="conductivity", xlab="Conductivity [mS/cm]")

# Example 3: colourize Conservative Temperature to indicate salinity.
# The markers are drawn without borders, to avoid black overpainting.
plot_profile(ctd, which="CT", markerstrokewidth=0.1, markersize=3, color_by="salinity")
```
"""
function plot_profile(d; which::String="CT", vertical::Symbol=:pressure,
    abbreviate::Symbol=:long, fontsize=8, color=:black, color_by=false,
    debug::Integer=0, kwargs...)
    # This test might be useful if further customization is needed for a future version
    # of the package. For now, it simply makes for better debugging output.
    if isa(d, Argo)
        oad(debug, "plot_profile(::Argo; which='$which', ...) START")
    elseif isa(d, Ctd)
        oad(debug, "plot_profile(::Ctd; which='$which', ...) START")
    else
        error("plot_profile() only works on Argo and Ctd objects")
    end
    # For all cases, we need to set up the vertical axis, so do that first
    oad(debug, "  setting up coordinate system for vertical axis")
    # Catch a problematic call
    if haskey(kwargs, :seriestype) && kwargs[:seriestype] == :line
        @warn "It is a *very* bad idea to use seriestype=:line in profile plots; use :path instead"
    end
    if vertical == :pressure
        y = d["pressure"]
        ylabel = label_from_varname("p", abbreviate)
    elseif vertical == :density
        y = d["sigma0"]
        ylabel = label_from_varname("sigma0", abbreviate)
    else
        error("vertical must be either :pressure or :density")
    end
    x = get_element(d, which, debug=increment_debug(debug))
    if isnothing(x)
        error("plot_profile() cannot find (or compute a value for) \"$which\"")
    end
    using_color_by = false
    if color_by != false
        if isa(color_by, String)
            oad(debug, "  color_by: \"", color_by, "\"")
            if color_by in names(d.data)
                color_by = decode_color_by(d[color_by])
                oad(debug, "  decoded palette details with decode_color_by()")
            elseif color_by == ""
                oad(debug, "  no palette will be drawn, since color_by=\"\"")
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
    title = pop!(kwargs_dict, :title, "")
    xlab = pop!(kwargs_dict, :xlab, label_from_varname(which))
    ylab = pop!(kwargs_dict, :ylab, ylabel)
    xlims = pop!(kwargs_dict, :xlims, extrema(skipmissing(x)))
    ylims = pop!(kwargs_dict, :ylims, reverse(extrema(skipmissing(y))))
    color = pop!(kwargs_dict, :color, :black)
    fig = Figure()
    ax = Axis(fig[1, 1],
        xaxisposition=:top,
        title=title,
        xlabel=xlab,
        ylabel=ylab,
        color=color,
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    limits!(ax, xlims[1], xlims[2], ylims[1], ylims[2])
    lines!(ax, x, y; color=color)
    return fig
    #<disabled>     p_profile = plot(x, y,
    #<disabled>         xlabel=label_from_varname(which), ylabel=ylabel,
    #<disabled>         yaxis=:flip, xmirror=true, framestyle=:box, legend=false,
    #<disabled>         color=color, tickdirection=:out,
    #<disabled>         seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4,
    #<disabled>         tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize,
    #<disabled>         yrot=90; kwargs...)
    #<disabled>     if using_color_by
    #<disabled>         if color_by == ""
    #<disabled>             oad(debug, "  not plotting symbols with individual colours, but leaving palette space")
    #<disabled>             p_cbar = plot(ticks=nothing, border=:none)
    #<disabled>             l = grid(1, 2, widths=[0.88, 0.12])
    #<disabled>             p_profile = plot(p_profile, p_cbar, layout=l)
    #<disabled>         else
    #<disabled>             oad(debug, "  plotting symbols with individual colours")
    #<disabled>             cindex = (color_by.levels .- color_by.clims[1]) / (color_by.clims[2] - color_by.clims[1])
    #<disabled>             colormap = cgrad(color_by.colorscheme)
    #<disabled>             markercolor = colormap[cindex]
    #<disabled>             plot!(x, y,
    #<disabled>                 seriestype=:scatter,
    #<disabled>                 linecolor=color, markercolor=markercolor,
    #<disabled>                 linewidth=1.0, marker=:circle, markersize=1.4;
    #<disabled>                 kwargs...)
    #<disabled>             p_cbar = scatter([1], [NaN], zcolor=[color_by.clims[1]], colormap=colormap, clims=color_by.clims, cbar=true, ticks=false, framestyle=:none, label="")
    #<disabled>             l = grid(1, 2, widths=[0.88, 0.12])
    #<disabled>             p_profile = plot(p_profile, p_cbar, layout=l)
    #<disabled>         end
    #<disabled>     end
    #<disabled>     oad(debug, "END plot_profile()")
    #<disabled>     return p_profile
end
export plot_profile

