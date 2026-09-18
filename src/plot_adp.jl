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
    ax, plot = plot_adp!(fig[1, 1], adp; which=which, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_adp()")
    return FigureAxisPlot(fig, ax, plot.main)
end
export plot_adp

function plot_adp!(fig_pos, adp::Adp; which=:velocity1, debug::Integer=0, kwargs...)
    oad(debug, "plot_adp!() START")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    oad(debug, "    inferred the following from kwargs (or from defaults):")
    color = pop!(kwargs_dict, :color, :black)
    oad(debug, "      • color:       $(oad_val(color))")
    colormap = pop!(kwargs_dict, :colormap, :balance)
    oad(debug, "      • colormap:    $(oad_val(colormap))")
    colorrange = pop!(kwargs_dict, :colorrange, :auto)
    oad(debug, "      • colorrange:  $(oad_val(colorrange))")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "      • fontsize:    $(oad_val(fontsize))")
    markersize = pop!(kwargs_dict, :markersize, 4)
    oad(debug, "      • markersize:  $(oad_val(markersize))")
    title = pop!(kwargs_dict, :title, :auto)
    oad(debug, "      • title:       $(oad_val(title))")
    xlabel = pop!(kwargs_dict, :xlabel, "x")
    oad(debug, "      • xlabel:      $(oad_val(xlabel))")
    ylabel = pop!(kwargs_dict, :ylabel, "y")
    oad(debug, "      • ylabel:      $(oad_val(ylabel))")
    # Check for unhandled keywords
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: colormap, colorrange, fontsize, ",
            "markersize, title, xlabel, and ylabel")
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
    if which in (:echo_intensity1, :echo_intensity2, :echo_intensity3, :echo_intensity4,
        :velocity1, :velocity2, :velocity3, :velocity4)
        oad(debug, "    handling which=$(repr(which))")
        beam = parse(Int, string(which)[end])
        is_echo = occursin(r"echo", String(which))
        is_velo = occursin(r"velocity", String(which))
        oad(debug, "    is_echo=$is_echo")
        oad(debug, "    is_velo=$is_velo")
        (is_echo || is_velo) || error("which must be of the form :velocityN or :echo_intensityN, where N is an integer in 1:nbeam")
        beam = parse(Int, string(which)[end])
        y = adp["distance"]
        if is_echo
            z = adp["echo_intensity"][:, :, beam]
        elseif is_velo
            z = adp["velocity"][:, :, beam]
        else
            error("FIXME: handle more than :velocityN and :echo_intensityN")
        end
        if colorrange == :auto
            if is_echo
                colorrange = extrema(abs.(z[.!isnan.(z)]))
            elseif is_velo
                colorrange = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)])) # centre colours on z=0
            end
        end
        @assert size(z) == (length(t), length(y)) "z is $(size(z)), expected $((length(t), length(y)))"
        # FIXME: do a trick to plot elapsed time on the x axis, but labelling it with DateTime
        # values.  I'll write a code to do that, since we may want this elsewhere ... and
        # since I imagine Makie will do this in a few weeks, given the active work
        # on a bug at https://github.com/MakieOrg/Makie.jl/issues/5193
        hour = (t .- t[1]) / Dates.Millisecond(1000) / 3600.0
        oad(debug, "    changing x name to \"Time [hour]\"")
        ax.xlabel = "Time [hour]"
        ax.ylabel = "Distance [m]"
        oad(debug, "    changing y name to \"Distance [m]\"")
        if title == :auto
            ax.title = "Beam $beam"
            oad(debug, "    changing title to \"Beam $beam\"")
        else
            ax.title = title
        end
        main = heatmap!(ax, hour, y, z, colormap=colormap, colorrange=colorrange, nan_color=:gray70)
        cb = Colorbar(fig_pos[1, 2], main, ticklabelsize=fontsize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main, cb=cb)
        # return ax, (main=hm, cb=cb)
    elseif which == :velocities
        oad(debug, "  handling which=$(repr(which))")
        error("FIXME: deprecate :velocities")
        #<> p1 = plot_adp(adp; which=:velocity1, debug=increment_debug(debug), kwargs...)
        #<> p2 = plot_adp(adp; which=:velocity2, debug=increment_debug(debug), kwargs...)
        #<> p3 = plot_adp(adp; which=:velocity3, debug=increment_debug(debug), kwargs...)
        #<> p4 = plot_adp(adp; which=:velocity4, debug=increment_debug(debug), kwargs...)
        #<> rval = plot(p1, p2, p3, p4, layout=@layout[a; b; c; d])
        #<> oad(debug, "END plot_adp()")
        #<> return (rval)
    elseif which == :heading
        oad(debug, "    handling the which=:heading case")
        main = scatter!(ax, t, adp["heading"], color=color, markersize=markersize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main,)
    elseif which == :pitch
        oad(debug, "    handling the which=:pitch case")
        main = scatter!(ax, t, adp["pitch"], ylab="Pitch [°]", color=color, markersize=markersize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main,)
    elseif which == :roll
        oad(debug, "    handling the which=:roll case")
        main = scatter!(ax, t, adp["roll"], ylab="Roll [°]", color=color, markersize=markersize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main,)
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
        oad(debug, "    handling the which=:uv case (showing all data)")
        adp["coordinate_system"] == :enu || error("plot with which=:$(which) requires :enu coordinates")
        velocity = adp["velocity"]
        bin = Int64(round(0.5 * size(velocity)[2]))
        oad(debug, "    bin: $bin")
        U = vec(velocity[:, :, 1])
        V = vec(velocity[:, :, 2])
        ax.aspect = DataAspect()
        ax.xlabel = "Eastward Velocity [m/s]"
        ax.ylabel = "North Velocity [m/s]"
        main = scatter!(ax, U, V, markersize=markersize, color=color)
        oad(debug, "END plot_adp()")
        return ax, (main=main,)
    else
        error("unrecognized value of which ($(repr(which)))")
    end
end
export plot_adp!
