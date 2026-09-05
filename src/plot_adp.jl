"""
    plot_adp(adp::Adp; which=:velocities, debug::Integer=0, kwargs...)

Plot the data stored in an [`Adp`](@ref) object.

This function provides some basic plots of the contents of an acoustic-Doppler
profiler ([`Adp`](@ref)) object.

# Arguments

- `adp` an Adp, as created with [`read_adp_rdi`](@ref).

- `which` a Symbol indicating what to plot.  If `which` is `:velocity1` then a
  [`heatmap`] plot is made of the first component of velocity.  It will be
  labelled as `"beam 1"`, `"ũ"` or `"u"`, according to whether
  `adp["coordinate_system"]` is `:beam`, `:xyz` or `:enu`. Similar results are
  obtained for `:velocity2` etc., where the fourth element is called `"ẽ"` or
  `"e"`, designating an error estimate.  If `which` is `velocities`, then the
  result is a multi-panel plot, with one panel per velocity component. If `which`
  is `:heading` then a time-series plot is made of heading, with analogous
  results for `:pitch` and `:roll`. If `which` is `:angles` then a three-panel
  plot is made, showing these three angles.  If `which` is `:uv` and
  `adp["coordinate_system"]` is `:enu`, then mid-distance east and north
  components of velocity are computed and then plotted in a scatterplot.

# Keywords

- `debug`: an optional integer value that, if it exceeds 0, indicates that
  debugging output should be printed during processing.

- `kwargs`: optional items, passed to `heatmap` for velocity fields, or to
  `scatter` for time-series and other x-y plots.

# Examples
```julia
using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000")
adp_beam = read_adp_rdi(file);
plot_adp(adp_beam)
adp_xyz = beam_to_xyz(adp_beam);
plot_adp(adp_xyz)
```
"""
function plot_adp(adp::Adp; which=:velocities, debug::Integer=0, kwargs...)
    error("plot_adp() disabled, pending convertion from Plots to Makie")
    #<disabled>     oad(debug, "plot_adp() START")
    #<disabled>     if adp["coordinate_system"] == :beam
    #<disabled>         titles = ["beam 1", "beam 2", "beam 3", "beam 4"]
    #<disabled>     elseif adp["coordinate_system"] == :xyz
    #<disabled>         titles = ["ũ", "ṽ", "w̃", "ẽ"]
    #<disabled>     elseif adp["coordinate_system"] == :enu
    #<disabled>         titles = ["u", "v", "w", "e"]
    #<disabled>     end
    #<disabled>     t = adp["time"]
    #<disabled>     if which in (:velocity1, :velocity2, :velocity3, :velocity4)
    #<disabled>         oad(debug, "  handling which=$(repr(which))")
    #<disabled>         beam = parse(Int, string(which)[end])
    #<disabled>         y = adp["distance"]
    #<disabled>         z = transpose(adp["velocity"][:, :, beam])
    #<disabled>         c = cgrad(:RdBu, rev=true)
    #<disabled>         clim = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)])) # centre colours on z=0
    #<disabled>         rval = heatmap(t, y, z,
    #<disabled>             title=titles[beam], titlelocation=:right,
    #<disabled>             framestyle=:box, tickdirection=:out,
    #<disabled>             guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
    #<disabled>             ylab="Distance [m]", background_color_inside=:gray70, c=c, clim=clim; kwargs...)
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return (rval)
    #<disabled>     elseif which == :velocities
    #<disabled>         oad(debug, "  handling which=$(repr(which))")
    #<disabled>         p1 = plot_adp(adp; which=:velocity1, debug=increment_debug(debug), kwargs...)
    #<disabled>         p2 = plot_adp(adp; which=:velocity2, debug=increment_debug(debug), kwargs...)
    #<disabled>         p3 = plot_adp(adp; which=:velocity3, debug=increment_debug(debug), kwargs...)
    #<disabled>         p4 = plot_adp(adp; which=:velocity4, debug=increment_debug(debug), kwargs...)
    #<disabled>         rval = plot(p1, p2, p3, p4, layout=@layout[a; b; c; d])
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return (rval)
    #<disabled>     elseif which == :heading
    #<disabled>         oad(debug, "  handling which=$(repr(which))")
    #<disabled>         rval = scatter(t, adp["heading"], ylab="Heading [°]",
    #<disabled>             label=false, framestyle=:box, guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
    #<disabled>             kwargs...)
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return (rval)
    #<disabled>     elseif which == :pitch
    #<disabled>         oad(debug, "  handling which=$(repr(which))")
    #<disabled>         rval = scatter(t, adp["pitch"], ylab="Pitch [°]",
    #<disabled>             label=false, framestyle=:box, guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
    #<disabled>             kwargs...)
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return (rval)
    #<disabled>     elseif which == :roll
    #<disabled>         oad(debug, "  handling which=$(repr(which))")
    #<disabled>         rval = scatter(t, adp["roll"], ylab="Roll [°]",
    #<disabled>             label=false, framestyle=:box, guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
    #<disabled>             kwargs...)
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return (rval)
    #<disabled>     elseif which == :angles
    #<disabled>         oad(debug, "  handling which=$(repr(which))")
    #<disabled>         p1 = plot_adp(adp; which=:heading, debug=increment_debug(debug), kwargs...)
    #<disabled>         p2 = plot_adp(adp; which=:pitch, debug=increment_debug(debug), kwargs...)
    #<disabled>         p3 = plot_adp(adp; which=:roll, debug=increment_debug(debug), kwargs...)
    #<disabled>         rval = plot(p1, p2, p3, layout=@layout[a; b; c])
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return (rval)
    #<disabled>     elseif which == :uv
    #<disabled>         adp["coordinate_system"] == :enu || error(":$(which) requires :enu coordinates")
    #<disabled>         oad(debug, "  handling which=$(repr(which)) for :enu coordinates")
    #<disabled>         velocity = adp["velocity"]
    #<disabled>         j = Int64(round(0.5 * size(velocity)[2]))
    #<disabled>         U = velocity[:, j, 1]
    #<disabled>         V = velocity[:, j, 2]
    #<disabled>         rval = scatter(U, V, aspect_ratio=1.0, label=false, framestyle=:box,
    #<disabled>             xlab="u [m/s]", ylab="v [m/s]", kwargs...)
    #<disabled>         oad(debug, "END plot_adp()")
    #<disabled>         return rval
    #<disabled>     else
    #<disabled>         error("unrecognized value of which ($(repr(which)))")
    #<disabled>     end
end
export plot_adp
