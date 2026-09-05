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
    error("plot_profile() disabled, pending convertion from Plots to Makie")
    #<disabled>     # This test might be useful if further customization is needed for a future version
    #<disabled>     # of the package. For now, it simply makes for better debugging output.
    #<disabled>     if isa(d, Argo)
    #<disabled>         oad(debug, "plot_profile(::Argo; which='$which', ...) START")
    #<disabled>     elseif isa(d, Ctd)
    #<disabled>         oad(debug, "plot_profile(::Ctd; which='$which', ...) START")
    #<disabled>     else
    #<disabled>         error("plot_profile() only works on Argo and Ctd objects")
    #<disabled>     end
    #<disabled>     # For all cases, we need to set up the vertical axis, so do that first
    #<disabled>     oad(debug, "  setting up coordinate system for vertical axis")
    #<disabled>     # Catch a problematic call
    #<disabled>     if haskey(kwargs, :seriestype) && kwargs[:seriestype] == :line
    #<disabled>         @warn "It is a *very* bad idea to use seriestype=:line in profile plots; use :path instead"
    #<disabled>     end
    #<disabled>     if vertical == :pressure
    #<disabled>         y = d["pressure"]
    #<disabled>         ylabel = label_from_varname("p", abbreviate)
    #<disabled>     elseif vertical == :density
    #<disabled>         y = d["sigma0"]
    #<disabled>         ylabel = label_from_varname("sigma0", abbreviate)
    #<disabled>     else
    #<disabled>         error("vertical must be either :pressure or :density")
    #<disabled>     end
    #<disabled>     x = get_element(d, which, debug=increment_debug(debug))
    #<disabled>     if isnothing(x)
    #<disabled>         error("plot_profile() cannot find (or compute a value for) \"$which\"")
    #<disabled>     end
    #<disabled>     using_color_by = false
    #<disabled>     if color_by != false
    #<disabled>         if isa(color_by, String)
    #<disabled>             oad(debug, "  color_by: \"", color_by, "\"")
    #<disabled>             if color_by in names(d.data)
    #<disabled>                 color_by = decode_color_by(d[color_by])
    #<disabled>                 oad(debug, "  decoded palette details with decode_color_by()")
    #<disabled>             elseif color_by == ""
    #<disabled>                 oad(debug, "  no palette will be drawn, since color_by=\"\"")
    #<disabled>             else
    #<disabled>                 error("color_by is \"", color_by, "\" which is neither \"\" nor in names(d.data)")
    #<disabled>             end
    #<disabled>         elseif isa(color_by, NamedTuple)
    #<disabled>             if length(color_by.levels) != nrow(d.data)
    #<disabled>                 error("length(color_by.levels)=", length(color_by.levels), " ≠ nrow(d.data)=", nrow(d.data))
    #<disabled>             end
    #<disabled>         else
    #<disabled>             error("color_by must be 'false', a String, or a NamedTuple")
    #<disabled>         end
    #<disabled>         using_color_by = true
    #<disabled>     end
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

