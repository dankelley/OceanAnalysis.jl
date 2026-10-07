"""
    plot_adp(adp::Adp; which=:velocity1, time_format=:datetime,
        debug::Integer=0, kwargs...)

    plot_adp!(fig_pos, adp::Adp; which=:velocity1, time_format=:datetime,
        debug::Integer=0, kwargs...)

Plot aspects of the data stored in an [`Adp`](@ref) object.

This function provides some basic plots of the contents of an acoustic-Doppler
profiler ([`Adp`](@ref)) object.

# Arguments

- `adp` an Adp, as created with [`read_adp_rdi`](@ref).

- `which` a Symbol indicating what to plot.  If `which` is `:velocity1` then a
  [`heatmap`] plot is made of the first component of velocity.  It will be
  entitled `"Beam 1"` or similar, according to the coordinate system
  (as stored in `adp["coordinate_system"]`).  A similar pattern
  holds for the other beams.  It also holds for `echo_intensity1`
  and so forth. There are also scatterplot diagrams, provided
  with `which` set to `:heading`, `:pitch`, `:roll` for instrument
  angles, and `:uv` for the Northward velocity component
  versus the Eastward velocity component.

# Keywords

- `time_format`: a Symbol indicating how to represent time, if that is
  on the x-axis of the chosen (heatmap) plot. The default, `:datetime`,
  indicates to use DateTime for the axis. Note that this is done with
  a kludge (as of October 2026), because Makie has a bug on heatmaps
  with time axes (see https://github.com/MakieOrg/Makie.jl/issues/5193).
  The other alternative is `:interval`, which will select hours, days
  or months, depending on the time span.

- `debug`: an optional integer value that, if it exceeds 0, indicates that
  debugging output should be printed during processing.

- `kwargs`: optional items, used variously.  The possibilities are
  `"colormap"`, `colorrange"`, `"fontsize"`, `"markersize"`, `"title"`,
  `"xlabel"`, and `"ylabel"`.

# Return value

The `plot_adp` form returns a Makie `FigureAxisPlot`, which can be displayed
directly or saved with the FileIO's `save`.

The `plot_adp!` form returns a Tuple with `ax` (a Makie `Axis`) as the first
item, and a NamedTuple as the second. The latter contains an element named
`main` that holds the main plot, plus potentially `cb` that holds a Colorbar.


# Examples
```julia
using OceanAnalysis
using GLMakie # or CairoMakie
# The data are in beam coordinates, so we transform to xyz, then enu
file= joinpath(pkgdir(OceanAnalysis), "data", "adp_rdi.000")
beam = read_adp_rdi(file);
xyz = beam_to_xyz(beam);
enu = xyz_to_enu(xyz, declination=-18.1); # decl for local region

# Single panel (beam 1)
plot_adp(beam, which=:velocity1)

# Single panel (east-north velocity)
plot_adp(enu, which=:uv)

# Four panel (uniform colourscale)
fig = Makie.Figure()
cr = (-1.5, 1.5)
plot_adp!(fig[1,1], enu, which=:velocity1, colorrange=cr, title="Eastward Upward Velocitym/s]")
plot_adp!(fig[1,2], enu, which=:velocity2, colorrange=cr, title="Northward Upward Velocitym/s]")
plot_adp!(fig[2,1], enu, which=:velocity3, colorrange=cr, title="Upward Velocity [m/s]")
plot_adp!(fig[2,2], enu, which=:velocity4, colorrange=cr, title="Error Velocity [m/s]")
```
"""
function plot_adp(adp::Adp; which=:velocity1, time_format=:datetime, debug::Integer=0, kwargs...)
    oad(debug, "plot_adp() START")
    fig = Makie.Figure()
    ax, plot = plot_adp!(fig[1, 1], adp;
        which=which, time_format=time_format, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_adp()")
    return Makie.FigureAxisPlot(fig, ax, plot.main)
end
export plot_adp

function plot_adp!(fig_pos, adp::Adp; which=:velocity1, time_format=:datetime, debug::Integer=0, kwargs...)
    oad(debug, "plot_adp!() START")
    oad(debug, "    which=$(repr(which))")
    oad(debug, "    time_format=$(repr(time_format))")
    time_format in [:datetime, :interval] || error("time_format must be :datetime or :interval")
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
    markersize = pop!(kwargs_dict, :markersize, 6)
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
    ax = Makie.Axis(fig_pos[1, 1], xlabel=xlabel, ylabel=ylabel,
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
    which_permitted = [:echo_intensity1, :echo_intensity2, :echo_intensity3, :echo_intensity4,
        :velocity1, :velocity2, :velocity3, :velocity4, :uv, :pitch, :roll, :heading]
    (which in which_permitted) || error("which=$(repr(which)) is not handled; try one of the following $(which_permitted)")
    if which in (:echo_intensity1, :echo_intensity2, :echo_intensity3, :echo_intensity4,
        :velocity1, :velocity2, :velocity3, :velocity4)
        oad(debug, "    handling which=$(repr(which))")
        y = adp["distance"]
        beam = parse(Int, string(which)[end])
        if occursin(r"echo", String(which))
            z = adp["echo_intensity"][:, :, beam]
            if colorrange == :auto
                colorrange = extrema(abs.(z[.!isnan.(z)]))
            end
        elseif occursin(r"velocity", String(which))
            z = adp["velocity"][:, :, beam]
            if colorrange == :auto
                colorrange = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)])) # centre colours on z=0
            end
        else
            error("programming error: should not be able to reach this point")
        end
        @assert size(z) == (length(t), length(y)) "z is $(size(z)), expected $((length(t), length(y)))"
        # Handle time axis for heatmap (sidestep a Makie bug)
        if time_format==:interval
            tstart, tend = extrema(t)
            interval = (tend - tstart) / Dates.Millisecond(1000)
            # Display by hours up to 2 days, and by days beyond that.
            # For larger time intervals, it makes sense to use the :datetime
            # method, for clarity of presentation ... BUT Makie has an
            # error on that.
            if interval <= 2 * 86400.0
                x = (t .- t[1]) / Dates.Millisecond(1000) / 3600.0
                ax.xlabel = "Time [hour]"
            else
                x = (t .- t[1]) / Dates.Millisecond(1000) / 86400.0
                ax.xlabel = "Time [day]"
            end
            oad(debug, "    changing x name to \"$(ax.xlabel)\"")
        else
            @warn "using a DateTime axis with a heatmap will yield a Makie error (as of 2026-10-07)"
            x = t # see below for error detection of this case (owing to a Makie bug)
        end
        ax.ylabel = "Distance [m]"
        oad(debug, "    changing y name to \"$(ax.ylabel)\"")
        if title == :auto
            ax.title = "Beam $beam"
            oad(debug, "    changing title to \"$(ax.title)\"")
        else
            ax.title = title
        end
        try
            oad(debug, "    about to draw a heatmap")
            main = Makie.heatmap!(ax, x, y, z, colormap=colormap, colorrange=colorrange, nan_color=:gray70)
            cb = Makie.Colorbar(fig_pos[1, 2], main, ticklabelsize=fontsize)
            oad(debug, "END plot_adp!()")
            return ax, (main=main, cb=cb)
        catch e
            if typeof(e) == StackOverflowError
                error("Makie cannot plot a heatmap with a DateTime axis (see https://github.com/MakieOrg/Makie.jl/issues/5193)")
            else
                error("Error in drawing a heatmap: \"$e\"")
            end
        end
    elseif which == :heading
        oad(debug, "    handling the which=:heading case")
        main = Makie.scatter!(ax, t, adp["heading"], color=color, markersize=markersize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main,)
    elseif which == :pitch
        oad(debug, "    handling the which=:pitch case")
        main = Makie.scatter!(ax, t, adp["pitch"], ylab="Pitch [°]", color=color, markersize=markersize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main,)
    elseif which == :roll
        oad(debug, "    handling the which=:roll case")
        main = Makie.scatter!(ax, t, adp["roll"], ylab="Roll [°]", color=color, markersize=markersize)
        oad(debug, "END plot_adp!()")
        return ax, (main=main,)
    elseif which == :uv
        oad(debug, "    handling the which=:uv case (showing all data)")
        adp["coordinate_system"] == :enu || error("plot with which=:$(which) requires :enu coordinates")
        velocity = adp["velocity"]
        bin = Int64(round(0.5 * size(velocity)[2]))
        oad(debug, "    bin: $bin")
        U = vec(velocity[:, :, 1])
        V = vec(velocity[:, :, 2])
        ax.aspect = Makie.DataAspect()
        ax.xlabel = "Eastward Velocity [m/s]"
        ax.ylabel = "North Velocity [m/s]"
        main = Makie.scatter!(ax, U, V, markersize=markersize, color=color)
        oad(debug, "END plot_adp()")
        return ax, (main=main,)
    else
        error("programming error: unhandled which value ($(repr(which))); please report this as an issue")
    end
end
export plot_adp!
