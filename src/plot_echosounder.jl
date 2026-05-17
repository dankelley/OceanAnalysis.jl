"""
    plot_echosounder(e::Echosounder; debug::Int64=0, kwargs...)

Plot the data stored in an [`Echosounder`](@ref) object.

This function provides some basic plots of the contents of an acoustic-Doppler profiler ([`Adp`](@ref)) object.

# Arguments

- `e` an Echosounder object, as created with [`read_echosounder`](@ref).

- `which` a Symbol indicating what to plot.  If `which` is `:log_amplitude` then a [`heatmap`] plot is made of the base-10 logarithm of the signal amplitude.  Eventually, other possible values of `which` may be handled.

# Keywords

- `debug`: an optional integer value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed to `heatmap`.

# Examples
```julia
using OceanAnalysis
f = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4";
if isfile(f)
    e = read_echosounder(f);
    plot_echosounder(e)
end
```
"""
function plot_echosounder(e::Echosounder; which=:log_amplitude, debug::Int64=0, kwargs...)
    oad(debug, "plot_echosounder() START")
    if which == :log_amplitude
        rval = heatmap(e["time"], e["range"], log10.(e.data["a"]), ylab="Range [m]",
            framestyle=:box, tickdirection=:out,
            guidefontsize=8, tickfontsize=8, titlefontsize=8, size=(800, 600),
            yflip=true; kwargs...)
    else
        error("only which=:log_amplitude is handled in this version of plot_echosounder.")
    end
    oad(debug, "END plot_echosounder()")
    return (rval)
end

