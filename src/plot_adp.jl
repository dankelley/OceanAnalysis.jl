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
using OceanAnalysis
using GLMakie # or CairoMakie
adp = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000") |> read_adp_rdi
plot_adp(adp)
```
"""
function plot_adp(adp::Adp; which=:velocities, debug::Integer=0, kwargs...)
    oad(debug, "plot_adp() START")
    fig = Figure()
    plot_adp!(fig[1, 1], adp; which=which, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_adp()")
    return fig
end
export plot_adp

function plot_adp!(fig_pos, adp::Adp; which=:velocities, debug::Integer=0, kwargs...)
    oad(debug, "plot_adp!() START")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    oad(debug, "    inferred the following from kwargs (or from defaults):")
    colormap = pop!(kwargs_dict, :colormap, :inferno)
    oad(debug, "      • colormap:    $(oad_val(colormap))")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "      • fontsize:    $(oad_val(fontsize))")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "      • title:       $(oad_val(title))")
    xlabel = pop!(kwargs_dict, :xlabel, "x")
    oad(debug, "      • xlabel:      $(oad_val(xlabel))")
    ylabel = pop!(kwargs_dict, :ylabel, "y")
    oad(debug, "      • ylabel:      $(oad_val(ylabel))")
    # Check for unhandled keywords
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: colormap, fontsize, title, xlabel, and ylabel")
    end
    ax = Axis(fig_pos[1, 1], xlabel=xlabel, ylabel=ylabel,
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    if adp["coordinate_system"] == :beam
        titles = ["beam 1", "beam 2", "beam 3", "beam 4"]
    elseif adp["coordinate_system"] == :xyz
        titles = ["ũ", "ṽ", "w̃", "ẽ"]
    elseif adp["coordinate_system"] == :enu
        titles = ["u", "v", "w", "e"]
    end
    t = adp["time"]
    if which in (:velocity1, :velocity2, :velocity3, :velocity4)
        oad(debug, "    handling which=$(repr(which))")
        beam = parse(Int, string(which)[end])
        println("DAN 1")
        y = adp["distance"]
        println("DAN 2")
        #z = transpose(adp["velocity"][:, :, beam])
        println("beam: $beam")
        z = adp["velocity"][:, :, beam]
        println("DAN 3")
        #c = cgrad(:RdBu, rev=true)
        println("DAN 4")
        colorrange = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)])) # centre colours on z=0
        println("DAN 5 (colorrange: $colorrange")
        println("DAN 6 length(t): $(length(t))")
        println("DAN 7 length(y): $(length(y))")
        println("DAN 8 size(z): $(size(z))")
        @assert size(z) == (length(t), length(y)) "z is $(size(z)), expected $((length(t), length(y)))"
        # FIXME: do a trick to plot elapsed time on the x axis, but labelling it with DateTime
        # values.  I'll write a code to do that, since we may want this elsewhere ... and
        # since I imagine Makie will do this in a few weeks, given the active work
        # on a bug at https://github.com/MakieOrg/Makie.jl/issues/5193
        plt = heatmap!(ax, t, y, z)#, colormap=colormap, colorrange=colorrange, nan_color=:gray70)
        println("draw Colorbar ...")
        cb = Colorbar(fig_pos[1, 2], plt, ticklabelsize=fontsize)
        oad(debug, "END plot_adp()")
        return (ax=ax, plt=plt, cb=cb)
    elseif which == :velocities
        oad(debug, "  handling which=$(repr(which))")
        error("FIXME: handle :velocities")
        #<> p1 = plot_adp(adp; which=:velocity1, debug=increment_debug(debug), kwargs...)
        #<> p2 = plot_adp(adp; which=:velocity2, debug=increment_debug(debug), kwargs...)
        #<> p3 = plot_adp(adp; which=:velocity3, debug=increment_debug(debug), kwargs...)
        #<> p4 = plot_adp(adp; which=:velocity4, debug=increment_debug(debug), kwargs...)
        #<> rval = plot(p1, p2, p3, p4, layout=@layout[a; b; c; d])
        #<> oad(debug, "END plot_adp()")
        #<> return (rval)
    elseif which == :heading
        oad(debug, "    handling the which=:heading case")
        plt = scatter(t, adp["heading"], ylab="Heading [°]")
        #<>    label=false, framestyle=:box, guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
        #<>    kwargs...)
        oad(debug, "END plot_adp!()")
        return plt
    elseif which == :pitch
        oad(debug, "    handling the which=:pitch case")
        plt = scatter!(ax, t, adp["pitch"], ylab="Pitch [°]")
        #<> label=false, framestyle=:box, guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
        #<< kwargs...)
        oad(debug, "END plot_adp!()")
        return plt
    elseif which == :roll
        oad(debug, "    handling the which=:roll case")
        plt = scatter!(ax, t, adp["roll"], ylab="Roll [°]")
        #label=false, framestyle=:box, guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
        #kwargs...)
        oad(debug, "END plot_adp!()")
        return plt
    elseif which == :angles
        oad(debug, "    handling the which=:angles case")
        error("FIXME: handle :angles")
        #<> p1 = plot_adp(adp; which=:heading, debug=increment_debug(debug), kwargs...)
        #<> p2 = plot_adp(adp; which=:pitch, debug=increment_debug(debug), kwargs...)
        #<> p3 = plot_adp(adp; which=:roll, debug=increment_debug(debug), kwargs...)
        #<> rval = plot(p1, p2, p3, layout=@layout[a; b; c])
        #<> oad(debug, "END plot_adp()")
        #<> return (rval)
    elseif which == :uv
        oad(debug, "    handling the which=:uv case")
        error("FIXME: handle :uv")
        #<> adp["coordinate_system"] == :enu || error(":$(which) requires :enu coordinates")
        #<> oad(debug, "  handling which=$(repr(which)) for :enu coordinates")
        #<> velocity = adp["velocity"]
        #<> j = Int64(round(0.5 * size(velocity)[2]))
        #<> U = velocity[:, j, 1]
        #<> V = velocity[:, j, 2]
        #<> rval = scatter(U, V, aspect_ratio=1.0, label=false, framestyle=:box,
        #<>     xlab="u [m/s]", ylab="v [m/s]", kwargs...)
        #<> oad(debug, "END plot_adp()")
        #<> return rval
    else
        error("unrecognized value of which ($(repr(which)))")
    end
end
export plot_adp!
