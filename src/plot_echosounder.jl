using Dates: Millisecond

"""
    plot_echosounder(e::Echosounder; debug::Integer=0, kwargs...)

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

- `kwargs`: optional items, passed to `heatmap`. At present, the only choices
  are `fontsize` (which defaults to 8), `colormap` (which defaults to `:inferno`)
  `colorrange` (which defaults to the extrema of the field specified by
  `which`), and `title` (which defaults to an indication of the start time
  of the dataset).

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
    oad(debug, "plot_echosounder() START")
    oad(debug, "    which=$which")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    colormap = pop!(kwargs_dict, :colormap, :inferno)
    oad(debug, "    colormap=$colormap")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "    fontsize=$fontsize")
    title = pop!(kwargs_dict, :title, "Start time $(e.metadata["time"][1])")
    if which == :log_amplitude
        fig = Figure()
        ax = Axis(fig[1, 1],
            xlabel="Elapsed time [s]", ylabel="Range [m]", title=title,
            yreversed=true,
            xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
            xticklabelsize=fontsize, yticklabelsize=fontsize)
        println("step 4a")
        z = log10.(e.data["a"])
        z[isinf.(z)] .= NaN
        println("step 4b ... typeof(z): $(typeof(z)), size: $(size(z))")
        colorrange = pop!(kwargs_dict, :colorrange,
            extrema(x for x in z if !isnan(x)))
        println("step 4c ... colorrange: $colorrange")
        sec = (e["time"] .- e["time"][1]) / Dates.Millisecond(1000)
        println("step 4d ... sec starts: $(sec[1:3])")
        range = collect(e["range"])
        println("step 4f ... range starts: $(range[1:3])")
        println("step 4g ABOUT TO DO heatmap")
        hm = heatmap!(ax, sec, range, z', colormap=colormap, colorrange=colorrange)
        println("step 4f heatmap worked; about to do Colorbar")
        Colorbar(fig[1, 2], hm, ticklabelsize=fontsize)
        println("step 4g Colorbar, all done")
        oad(debug, "END plot_echosounder()")
        return fig
    else
        error("only which=:log_amplitude is handled by plot_echosounder().")
    end
end
export plot_echosounder

