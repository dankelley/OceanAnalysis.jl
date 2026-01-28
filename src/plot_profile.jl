"""
    plot_profile(ctd::Ctd; which::String="CT", vertical::String="pressure",
        abbreviate::Bool=false, legend::Bool=false, tickfontsize=8, tickdirection=:out,
        guidefontsize=8, debug::Int64=0, kwargs...)

Plot an oceanographic profile for data contained in `ctd`, showing how the
variable named by `which` depends on pressure.  The variable is drawn on the x
axis and pressure on the y axis. Following oceanographic convention, pressure
increases downwards on the page and the "x" axis is drawn at the top. The
permitted values of `which` are
`"CT"` for the Gibbs Seawater formulation of Conservative Temperature,
`"N2"` for N², the square of the buoyancy frequency,
`"SA"` for the Gibbs Seawater formulation of Absolute Salinity,
`"salinity"` for Practical Salinity,
`"sigma0"` for the Gibbs Seawater formulation of density anomaly referenced to the surface,
`"spiciness0"` for the Gibbs Seawater seawater spiciness referenced to the surface,
and
`"temperature"` for in-situ temperature.

The default Julia font sizes on axes are overridden in this function, with
8-point being used for both the numbers on axes (`tickfontize`) and the names
of axes (`guidefontsize`).  (The `tickfontsize` matches the Julia default,
but the `guidefontsize` is smaller than the Julia default. The idea is to
not waste space by using fonts that are larger than what journals require.)

The `kwargs...` argument is used for arguments to be sent to `plot()`.  For
example, the default way to display the profile diagram is constructed with a
blue line connecting points, but using e.g.
```julia
plot_profile(ctd, which="SA", seriestype=:scatter, seriescolor=:red)
```
yields red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on the many plotting controls available in Julia. Note that
specifying `seriestype=:line` will yield a warning, and the
value will be changed to `:path` for the plot.

See also the [`plot_TS`](@ref) function.

# Examples
```julia
using OceanAnalysis, Plots
# Read an Argo file
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = read_argo(f);
# Plot profiles of Conservative Temperature, Absolute Salinity, and potential
# density anomaly with respect to surface pressure.
p1 = plot_profile(d, which="CT")
p2 = plot_profile(d, which="SA")
p3 = plot_profile(d, which="sigma0")
plot(p1, p2, p3, layout=(1, 3), size=(800, 400))
```
"""
function plot_profile(ctd::Ctd; which::String="CT", vertical::String="pressure",
    seriestype=:path, abbreviate::Bool=false, legend::Bool=false, tickfontsize=8, tickdirection=:out,
    guidefontsize=8, debug::Int64=0, kwargs...)
    oad(debug, "plot_profile(<ctd>, '$which') START")
    data_names = names(ctd.data)
    # We can plot proviles of whatever is in the file, plus some others. Of course,
    # we don't allow plotting a profile of pressure, since that's just a silly 1:1
    # line.
    plot_names = data_names[data_names.!="pr".&&data_names.!="pressure"]
    oad(debug, "    plotnames before adding derived variables: ", plot_names)
    derived_variables = ["SA", "CT", "sigma0", "spiciness0", "N2"]
    for item in derived_variables
        if !(item in plot_names)
            plot_names = [plot_names; item]
        end
    end
    oad(debug, "    plotnames after adding derived variables: ", plot_names)
    if !(which in plot_names)
        error("plot_profile() cannot handle which='", which, "'; try one of: ", plot_names)
    end
    oad(debug, "    extracting data")
    S = ctd.data.salinity
    T = ctd.data.temperature
    p = ctd.data.pressure
    # Computing things as below is fast in Julia, so we do it even if the user
    # doesn't actually want SA or the other TEOS-10 variable.  And, I think in
    # many cases, the user *will* want those TEOS-10 things.
    SA = ctd["SA"]
    CT = ctd["CT"]
    sigma0 = ctd["sigma0"]
    spiciness0 = ctd["spiciness0"]
    oad(debug, "    setting up coordinate system for vertical axis")
    if seriestype == :line
        @warn "plot_profile() switching seriestype from :line to :path"
        seriestype = :path
    end
    y = vertical == "pressure" ? p : sigma0
    if vertical == "pressure"
        y = p
        ylabel = abbreviate ? "p [dbar]" : "Pressure [dbar]"
    elseif vertical == "density"
        y = sigma0
        ylabel = abbreviate ? "σ₀ [kg/m³]" : "Potential Density Anomaly [kg/m³]"
    else
        error("vertical must be either \"pressure\" or \"density\"")
    end
    if which == "temperature" || which == "CT"
        oad(debug, "    drawing '", which, "'")
        rval = plot(which == "CT" ? CT : T, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash,
            tickfontsize=tickfontsize, tickdirection=tickdirection,
            guidefontsize=guidefontsize,
            xlabel=if (abbreviate)
                which == "CT" ? "CT[°C]" : "T [°C]"
            else
                which == "CT" ? "Conservative Temperature [°C]" : "Temperature [°C]"
            end,
            yrot=90; kwargs...)
    elseif which == "salinity" || which == "SA"
        oad(debug, "    drawing '", which, "'")
        rval = plot(which == "SA" ? SA : S, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash,
            tickfontsize=tickfontsize, tickdirection=tickdirection,
            guidefontsize=guidefontsize,
            xlabel=if (abbreviate)
                which == "SA" ? "SA [g/kg]" : "S"
            else
                which == "SA" ? "Absolute Salinity [g/kg]" : "Practical Salinity"
            end,
            yrot=90; kwargs...)
    elseif which == "sigma0" # gsw formulation
        oad(debug, "    drawing '", which, "'")
        rval = plot(sigma0, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash,
            tickfontsize=tickfontsize, tickdirection=tickdirection,
            guidefontsize=guidefontsize,
            xlabel=if abbreviate
                "σ₀ [kg/m³]"
            else
                "Potential Density Anomaly, σ₀ [kg/m³]"
            end,
            yrot=90; kwargs...)
    elseif which == "spiciness0" # gsw formulation
        oad(debug, "    drawing '", which, "'")
        rval = plot(spiciness0,
            y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash,
            tickfontsize=tickfontsize, tickdirection=tickdirection,
            guidefontsize=guidefontsize,
            xlabel=if abbreviate
                "π [kg/m³]"
            else
                "Spiciness [kg/m³]"
            end,
            yrot=90; kwargs...)
    elseif which == "N2"
        oad(debug, "    drawing '", which, "'")
        x = N2(ctd)
        rval = plot(x, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash,
            tickfontsize=tickfontsize, tickdirection=tickdirection,
            guidefontsize=guidefontsize,
            xlabel=if abbreviate
                "N²" # N2" #"N²"
            else
                "N² [s⁻²]" # "N2 [1/s^2]"
            end,
            yrot=90; kwargs...)
    elseif which in plot_names
        x = ctd.data[:, which]
        oad(debug, "    drawing $which")
        rval = plot(x, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash,
            tickfontsize=tickfontsize, tickdirection=tickdirection,
            guidefontsize=guidefontsize,
            xlabel=which,
            yrot=90; kwargs...)
    else
        error("Unrecognized 'which'=\"$(which)\". Try 'CT', 'N2', 'S', 'SA', 'sigma0', 'spiciness0', or 'T'.")
    end
    oad(debug, "END plot_profile()")
    rval
end

