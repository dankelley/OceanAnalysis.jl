"""
    plot_profile(ctd::Ctd; which::String="CT", vertical::Symbol=:pressure,
        abbreviate::Symbol=:long, fontsize::Integer=8, debug::Integer=0, kwargs...)

Plot an oceanographic profile for data contained in `ctd`, showing how the variable named by `which` depends on either pressure or density.  The variable is drawn on the x axis and pressure on the y axis. Following oceanographic convention, the y axis is set up so that waters nearer the air-sea interface are nearer the top of the plot.

# Arguments

- `ctd` a Ctd object to be plotted.

# Keywords

- `which` an indication of what to plot on the x axis. The default value, `"CT"`, indicates to plot Conservative Temperature. Anything stored in the object's `data` can be plotted, along with some things that can be calculated from these values. Common choices include: `"N2"` for N², the square of the buoyancy frequency; `"SA"` for the Gibbs Seawater formulation of Absolute Salinity; `"salinity"` for Practical Salinity; `"sigma0"` for the Gibbs Seawater formulation of density anomaly referenced to the surface; `"spiciness0"` for the Gibbs Seawater seawater spiciness referenced to the surface; and `"temperature"` for in-situ temperature.

- `vertical` a Symbol specifying what to plot on the y axis. The default is `:pressure`, but `:density` is also permitted.

- `abbreviate` a Symbol indicating a category for axis length, used in determining how to label the axes. The valid choices are `:short`, `:medium`, and `:long`.

- `fontsize` size of fonts to be supplied to [plot] as `tickfontsize`, `guidefontsize` and `titlefontsize`. Note that any of these values may also be supplied as named arguments within `kwargs...`.

- `debug` indicator of debugging level. If this exceeds 0, some information is printed during processing.

- `kwargs...` is passed to `plot()`, to permit further customization; see https://docs.juliaplots.org/stable/ for more information on possibilities.


# Examples
```julia
using OceanAnalysis, Plots

# Example 1: show overview of an Argo profile
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
ctd = read_argo(f) |> as_ctd;
# Plot profiles of Conservative Temperature, Absolute Salinity, and potential
# density anomaly with respect to surface pressure.
p1 = plot_profile(ctd; which="CT")
p2 = plot_profile(ctd; which="SA")
p3 = plot_profile(ctd; which="sigma0")
plot(p1, p2, p3, layout=(1, 3), size=(800, 400))

# Example 2: add a new variable to the profile, then plot it
using GibbsSeaWater
ctd.data.conductivity = gsw_c_from_sp.(ctd["salinity"], ctd["temperature"], ctd["pressure"]);
plot_profile(ctd, which="conductivity", xlab="Conductivity [mS/cm]")
```
"""
function plot_profile(ctd::Ctd; which::String="CT", vertical::Symbol=:pressure,
    abbreviate::Symbol=:long, fontsize::Integer=8, debug::Integer=0, kwargs...)
    oad(debug, "plot_profile(<ctd>, which='$which') START")
    # For all cases, we need to set up the vertical axis, so do that first
    oad(debug, "  setting up coordinate system for vertical axis")
    if haskey(kwargs, :seriestype) && kwargs[:seriestype] == :line
        @warn "It is a *very* bad idea to use seriestype=:line in profile plots; use :path instead"
    end
    if vertical == :pressure
        y = ctd["pressure"]
        ylabel = label_from_varname("p", abbreviate)
    elseif vertical == :density
        y = ctd["sigma0"]
        ylabel = label_from_varname("sigma0", abbreviate)
    else
        error("vertical must be either :pressure or :density")
    end
    x = get_element(ctd, which, debug=increment_debug(debug))
    if isnothing(x)
        error("Cannot find \"$which\" in this object, and cannot compute it either")
    end
    rval = plot(x, y,
        xlabel=label_from_varname(which), ylabel=ylabel,
        yaxis=:flip, xmirror=true, framestyle=:box, legend=false,
        color=:black, tickdirection=:out,
        seriestype=:path, linewidth=1.0, marker=:circle, markersize=1.4,
        tickfontsize=fontsize, guidefontsize=fontsize, titlefontsize=fontsize,
        yrot=90; kwargs...)
    oad(debug, "END plot_profile()")
    return rval
end

