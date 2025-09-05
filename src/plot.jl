"""
    plot_profile(ctd::Ctd, which::String="CT"; vertical::String="pressure",
        abbreviate::Bool=false, legend::Bool=false,
        tickfontsize=8, labelfontsize=8, debug::Int64=0, kwargs...)

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
of axes (`labelfontsize`).  (The `tickfontsize` matches the Julia default,
but the `labelfontsize` is smaller than the Julia default. The idea is to
not waste space with fonts that are larger than what journals require.)

The `kwargs...` argument is used for arguments to be sent to `plot()`.  For
example, the default way to display the profile diagram is constructed with a
blue line connecting points, but using e.g.
```julia-repl
plot_profile(ctd, "SA", seriestype=:scatter, seriescolor=:red)
```
yields red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on the many plotting controls available in Julia.

# Examples
```julia
using OceanAnalysis, Plots
# Read an Argo file
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = read_argo(f, 1);
# Plot profiles of Conservative Temperature, Absolute Salinity, and potential
# density anomaly with respect to surface pressure.
p1 = plot_profile(d, "CT")
p2 = plot_profile(d, "SA")
p3 = plot_profile(d, "sigma0")
plot(p1, p2, p3, layout=(1, 3), size=(800, 400))
```

See also the [`plot_TS`](@ref) function.
"""
function plot_profile(ctd::Ctd, which::String="CT"; vertical::String="pressure", abbreviate::Bool=false,
    legend::Bool=false, tickfontsize=8, labelfontsize=8,
    debug::Int64=0, kwargs...)
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
    if which in derived_variables
        SA_ = SA(ctd)
        CT_ = CT(ctd)
        sigma0_ = gsw_sigma0.(SA_, CT_)
        spiciness0_ = gsw_spiciness0.(SA_, CT_)
    end
    oad(debug, "    setting up coordinate system for vertical axis")
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
        rval = plot(which == "CT" ? CT_ : T, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if (abbreviate)
                which == "CT" ? "CT[°C]" : "T [°C]"
            else
                which == "CT" ? "Conservative Temperature [°C]" : "Temperature [°C]"
            end,
            yrot=90; kwargs...)
    elseif which == "salinity" || which == "SA"
        oad(debug, "    drawing '", which, "'")
        rval = plot(which == "SA" ? SA_ : S, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if (abbreviate)
                which == "SA" ? "SA [g/kg]" : "S"
            else
                which == "SA" ? "Absolute Salinity [g/kg]" : "Practical Salinity"
            end,
            yrot=90; kwargs...)
    elseif which == "sigma0" # gsw formulation
        oad(debug, "    drawing '", which, "'")
        rval = plot(sigma0_, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if abbreviate
                "σ₀ [kg/m³]"
            else
                "Potential Density Anomaly, σ₀ [kg/m³]"
            end,
            yrot=90; kwargs...)
    elseif which == "spiciness0" # gsw formulation
        oad(debug, "    drawing '", which, "'")
        rval = plot(spiciness0_,
            y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
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
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
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
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=which,
            yrot=90; kwargs...)
    else
        error("Unrecognized 'which'=\"$(which)\". Try 'CT', 'N2', 'S', 'SA', 'sigma0', 'spiciness0', or 'T'.")
    end
    oad(debug, "END plot_profile()")
    rval
end

"""
    plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
        draw_freezing=true, abbreviate=false,
        framestyle=:box, color=:black, seriestype=:scatter, ms=2,
        legend=false, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
        debug::Int64=0, kwargs...)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.

By default, contours of sigma0 are shown, but contours of spiciness0 are not
shown. The parameters `sigma0_levels` and `spiciness0_levels` control
contouring. Setting the respective value to 0 prevents contouring.  Setting it
to a positive integer provides a suggestion for the number of levels, with the
actual number being set by [`pretty`](@ref)), which is provided with the
integer.  Setting it to an empty vector, i.e. `[]`, causes automatic selection
of levels, again with `[pretty`](@ref).  And, finally, setting it to a vector
of numbers specifies those numbers as the levels.

By default, a freezing-point line is drawn (if it is within the range of the
data); this drawing is turned off if `draw_freezing` is set to false.

By default, axis names are written in long form; set `abbreviate=true` for
shorter versions.

Information about the analysis is printed if `debug` is set to true.

Apart from that, the other parameters have the usual meanings for Julia plots.
For example, `color` is set to black, to override the Julia default, etc.

# Examples
```julia-repl
# Display hydrographic properties stored in a built-in Argo file
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = read_argo(f, 1)
plot_TS(d)
```

See also [`plot_profile`](@ref).
"""
function plot_TS(ctd::Ctd; sigma0_levels=[], spiciness0_levels=0,
    draw_freezing=true, abbreviate=false,
    framestyle=:box, color=:black, seriestype=:scatter, ms=2,
    legend=false, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
    debug::Int64=0, kwargs...)
    oad(debug, "plot_TS(<ctd>) START")
    local S = ctd.data.salinity
    local T = ctd.data.temperature
    local p = ctd.data.pressure
    local lon = ctd.metadata["longitude"]
    local lat = ctd.metadata["latitude"]
    SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
    # We start with the measurements ... 
    oad(debug, "    drawing data")
    rval = plot(SA, CT, legend=legend,
        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
        ylabel=abbreviate ? "C [°C]" : "Conservative Temperature [°C]",
        yrot=90, framestyle=framestyle,
        seriestype=seriestype, ms=ms,
        gridstyle=gridstyle, color=color, tickfontsize=tickfontsize,
        labelfontsize=labelfontsize; kwargs...)
    # ... then add density contours ...
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    oad(debug, "    processing sigma0 contours")
    sigma0c = gsw_sigma0.(SAc', CTc) |> fix_gsw_bad_code!
    local levels = sigma0_levels
    if length(sigma0_levels) == 0
        oad(debug, "        case 1: sigma0_levels is empty, so auto-compute sigma0 contour levels")
        levels = pretty(sigma0c) # returns [] if min=max
    elseif length(sigma0_levels) == 1 && typeof(sigma0_levels) == Int64
        oad(debug, "        case 2: sigma0_levels is a single integer")
        if sigma0_levels > 0
            levels = pretty(sigma0c, sigma0_levels)
        else
            levels = []
        end
    else
        oad(debug, "        case 3: sigma0_levels is a vector of sigma0 levels for contouring")
    end
    if length(levels) > 0
        oad(debug, "        drawing sigma0 contours at levels $(levels)")
        contour!(SAc, CTc, sigma0c, color=:gray50, linewidth=1.0, levels=levels,
            cbar=false, clabels=true)
    else
        oad(debug, "        not drawing sigma0 contours")
    end
    # ... then (optionally) add spiciness contours ...
    oad(debug, "    processing spiciness0 contours")
    spiciness0c = gsw_spiciness0.(SAc', CTc) |> fix_gsw_bad_code!
    local levels = spiciness0_levels
    if length(spiciness0_levels) == 0
        oad(debug, "        case 1: spiciness0_levels is empty, so auto-compute spiciness0 contour levels")
        levels = pretty(spiciness0c)
    elseif length(spiciness0_levels) == 1 && typeof(spiciness0_levels) == Int64
        oad(debug, "        case 2: spiciness0_levels is a single integer")
        if spiciness0_levels > 0
            levels = pretty(spiciness0c, spiciness0_levels)
        else
            levels = []
        end
    else
        oad(debug, "        case 3: spiciness0_levels is a vector of spiciness0 levels for contouring")
    end
    if length(levels) > 0
        oad(debug, "    drawing spiciness0 contours at levels $(levels)")
        contour!(SAc, CTc, spiciness0c, color=:gray50, linewidth=1.0, levels=levels,
            cbar=false, clabels=true)
    else
        oad(debug, "        not drawing spiciness0 contours")
    end
    # ... and finally (optionally) add a freezing-temperature line.
    if draw_freezing
        oad(debug, "    adding freezing line")
        pf = 0.0 # let user specify this?
        SAf = range(xlim[1], xlim[2], length=100)
        saturation_fraction = 0.0
        CTf = gsw_ct_freezing.(SAf, pf, saturation_fraction)
        plot!(xlim=xlim, ylim=ylim)
        plot!(SAf, CTf, color=:blue, linewidth=0.5, linestyle=:dash)
    end
    oad(debug, "END plot_TS()")
    rval
end # plot_TS()

