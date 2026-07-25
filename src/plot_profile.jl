"""
    plot_profile(d::Union{Argo,Ctd}; which::String="CT", vertical::Symbol=:pressure,
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
  individually according to some specified value. If `color_by=false`, then this
  is not done, and all points are painted with `color`. To colorize the points
  according to the value of column in `d.data`, set `color_by` to the name of
  that column. This yields a default colour scheme, displayed in a palette to the
  right of the main graph (see Example 3). Greater control over the colorscheme
  is provided by setting `color_by` to a NamedTuple that is constructed a call
  to [`decode_color_by`](@ref).

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
plot_profile(ctd, which="CT", markerstrokewidth=0, markersize=3, color_by="salinity")
```
"""
function plot_profile(d::Union{Argo,Ctd}; which::String="CT", vertical::Symbol=:pressure,
    abbreviate::Symbol=:long, fontsize=8, color=:black, color_by=false,
    debug::Integer=0, kwargs...)
    # This test might be useful if further customization is needed for a future version
    # of the package. For now, it simply makes for better debugging output.
    if isa(d, Argo)
        oad(debug, "plot_profile(::Argo; which='$which', ...) START")
    else
        oad(debug, "plot_profile(::Ctd; which='$which', ...) START")
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
            color_by in names(d.data) || error("color_by, a String, is not in names(d.data)")
            oad(debug, "  creating color_by for data column named \"$color_by\"")
            color_by = decode_color_by(d[color_by])
        else
            isa(color_by, NamedTuple) || error("color_by must be 'false' or a NamedTuple")
        end
        length(color_by.levels) == nrow(d.data) || error("length of color_by.levels, $(length(color_by.levels)), does not equal nrow(d.data), $(nrow(d.data))")
        using_color_by = true
    end
    p_profile = plot(x, y,
        xlabel=label_from_varname(which), ylabel=ylabel,
        yaxis=:flip, xmirror=true, framestyle=:box, legend=false,
        color=color, tickdirection=:out,
        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4,
        tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize,
        yrot=90; kwargs...)
    if using_color_by
        oad(debug, "  plotting symbols with individual colours")
        cindex = (color_by.levels .- color_by.clims[1]) / (color_by.clims[2] - color_by.clims[1])
        colormap = cgrad(color_by.colorscheme)
        markercolor = colormap[cindex]
        plot!(x, y,
            seriestype=:scatter,
            linecolor=color, markercolor=markercolor,
            linewidth=1.0, marker=:circle, markersize=1.4;
            kwargs...)
        p_cbar = scatter([1], [NaN], zcolor=[color_by.clims[1]], colormap=colormap, clims=color_by.clims, cbar=true, ticks=false, framestyle=:none, label="")
        l = grid(1, 2, widths=[0.88, 0.12])
        p_profile = plot(p_profile, p_cbar, layout=l)
        #<?> else...
    end
    oad(debug, "END plot_profile()")
    return p_profile
end
export plot_profile

