using Dates: Millisecond

"""
    plot_echosounder(e::Echosounder;
        which=:log_amplitude, debug::Integer=0, kwargs...)

    plot_echosounder!(fig_pos, e::Echosounder;
        which=:log_amplitude, debug::Integer=0, kwargs...)

Plot the data stored in an [`Echosounder`](@ref) object.

This function provides some basic plots of the contents of an
([`Echosounder`](@ref)) object.

# Arguments

- `e` an Echosounder object, as created with [`read_echosounder`](@ref).

- `which` a Symbol indicating what to plot.  If `which` is `:log_amplitude`
  then a [`heatmap`] plot is made of the base-10 logarithm of the signal
  amplitude.  Eventually, other possible values of `which` may be handled.

# Keywords

- `debug`: an optional integer value that, if it exceeds 0, indicates that
  debugging output should be printed during processing.

- `kwargs`: other named arguments. The possibilities are: `colormap` to set the
  colormap (which defaults to `:inferno`), `colorrange` to set the color range
  (which defaults tothe full range of data), `fontsize` to set the fontsize
  (which defaults to 8). and `title` to set the plot title (which defaults to
  a statement of the start time).

# Return value

The `plot_echosounder()` form returns a `Makie.Figure`, which can be displayed
directly or saved with `save("filename.png", fig)`.

The `plot_echosounder!()` form returns a NamedTuple containing `ax` (a
`Makie.Axis`), `hm_plt` (a Makie `Heatmap` object) and `hm_cb` (a Colorbar
object).

# Examples
```julia
using OceanAnalysis, CairoMakie
f = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4";
if isfile(f)
    e = read_echosounder(f);
    plot_echosounder(e)
end
```
"""
function plot_echosounder(e::Echosounder; which=:log_amplitude, debug::Integer=0, kwargs...)
    oad(debug, "plot_echosounder() BEGIN")
    fig = Figure()
    plot_echosounder!(fig[1, 1], e; which=which, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_echosounder()")
    return fig
end
export plot_echosounder

function plot_echosounder!(fig_pos, e::Echosounder; which=:log_amplitude, debug::Integer=0, kwargs...)
    oad(debug, "plot_echosounder!() START")
    oad(debug, "    which=$which")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    colormap = pop!(kwargs_dict, :colormap, :inferno)
    oad(debug, "    colormap=$colormap")
    colorrange = pop!(kwargs_dict, :colorrange, (nothing, nothing))
    oad(debug, "    colorrange=$colorrange (initial)")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "    fontsize=$fontsize")
    title = pop!(kwargs_dict, :title, "Start time $(e.metadata["time"][1])")
    oad(debug, "    title=$title")
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: color, colormap, fontsize, ",
            "and title")
    end
    ax = Axis(fig_pos[1, 1],
        title=title, xlabel="Elapsed time [s]", ylabel="Range [m]",
        yreversed=true,
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    if which == :log_amplitude
        z = log10.(e.data["a"])
        z[isinf.(z)] .= NaN
        if colorrange == (nothing, nothing)
            colorrange = extrema(x for x in z if !isnan(x))
            oad(debug, "    colorrange=$colorrange (based on data)")
        end
        sec = (e["time"] .- e["time"][1]) / Dates.Millisecond(1000)
        range = collect(e["range"]) # FIXME: do we need to collect?
        oad(debug, "    drawing heatmap, with elapsed time range $(extrema(sec))")
        hm_plt = heatmap!(ax, sec, range, z', colormap=colormap, colorrange=colorrange)
        oad(debug, "    drawing ColorBar")
        cb_plt = Colorbar(fig_pos[1, 2], hm_plt, label="Log10(amplitude)",
            labelsize=fontsize, ticklabelsize=fontsize)
        oad(debug, "END plot_echosounder!()")
        return (ax, hm_plt, cb_plt)
    else
        error("only which=:log_amplitude is handled by plot_echosounder().")
    end
end
export plot_echosounder!

