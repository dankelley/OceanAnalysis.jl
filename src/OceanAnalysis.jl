module OceanAnalysis

using NCDatasets
using DataFrames
using GibbsSeaWater
using Plots
using CSV
using Dierckx
using Statistics

# Structs
export Oce
export Ctd
#. export Argo

# Functions
export as_Ctd
export coordinateFromString
export getElement
export N2
export plotProfile
export plotTS
export readArgo
export readCtdCNV
export T90fromT48
export T90fromT68
export debug_space

abstract type Oce end

struct Ctd <: Oce
    #header::Vector{String}
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
    # salinity::Vector{Float64}
    # temperature::Vector{Float64}
    # pressure::Vector{Float64}
    # longitude::Float64
    # latitude::Float64
    # SA::Vector{Float64}
    # CT::Vector{Float64}
    # sigma0::Vector{Float64}
    # spiciness0::Vector{Float64}
end

function debug_space(debug::Int64, max::Int64=3)
    0 < debug <= max ? repeat("  ", max - debug) : ""
end

"""
    degree = coordinateFromString(s::String)

Try to extract a longitude or latitude from a string. If there are two
(space-separated) tokens in the string, the first is taken as the decimal
degrees, and the second as decimal minutes. The goal is to parse hand-entered
strings, which might contain letters like `"W"` and `"S"` (or the same
in lower case) to indicate the hemisphere. Humans are quite good at writing
confusing strings, so this function is not always helpful.

# Examples
```julia-repl
coordinateFromString("1.5")   # 1.5
coordinateFromString("1 30")  # 1.5
coordinateFromString("1S 30") # -1.5
```
"""
function coordinateFromString(s::String)
    sign = occursin(r"[wWsS]", s) ? -1.0 : 1.0
    s = replace(s, r"[nNsSeEwW]" => "")
    tokens = split(s)
    if length(tokens) == 1
        return sign * parse(Float64, s)
    elseif length(tokens) == 2
        return sign * (parse(Float64, tokens[1]) + parse(Float64, tokens[2]) / 60.0)
    else
        error("malformed coordinate string \"$s\"")
    end
end


"""
    Ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64},
        longitude::Float64=-30, latitude::Float64=30)

Construct a `Ctd` structure, given vectors Practical Salinity, in-situ
Temperature, and sea pressure, along with single numbers indicating longitude
and latitude. Note that the last two are needed for the computation of Absolute
Salinity, Conservative Temperature, sigma0 and spicines0, all of which are
which are stored in the returned value alongside the three supplied vectors.

"""
# Convenience function, which carries out TEOS-10 computations
function as_Ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64},
    longitude::Float64=-30.0, latitude::Float64=30.0,
    debug::Int64=0)
    ds = debug_space(debug)
    if debug > 0
        println("$ds as_Ctd() START")
        println("  $ds salinity length: ", length(salinity))
        println("  $ds temperature length: ", length(temperature))
        println("  $ds pressure length: ", length(pressure))
        println("  $ds longitude length: ", length(longitude))
        println("  $ds latitude length: ", length(latitude))
    end
    #println("in Ctd() at line 101")
    local SA = gsw_sa_from_sp.(salinity, pressure, longitude, latitude)
    if debug > 0
        println("  $ds SA length: ", length(SA))
    end
    #println("in Ctd() at line 103")
    local CT = gsw_ct_from_t.(SA, temperature, pressure)
    if debug > 0
        println("  $ds CT length: ", length(CT))
    end
    #println("in Ctd() at line 105")
    spiciness0 = gsw_spiciness0.(SA, CT)
    if debug > 0
        println("  $ds spiciness0 length: ", length(spiciness0))
    end
    #println("in Ctd() at line 107")
    sigma0 = gsw_sigma0.(SA, CT)
    if debug > 0
        println("  $ds sigma0 length: ", length(sigma0))
    end
    #println("in Ctd() at line 109")
    # Next uses a constructor (FIXME: is that true?)
    #ctd = as_Ctd(salinity, temperature, pressure, longitude, latitude, SA, CT, sigma0, spiciness0)
    error("FIXME: need to set up metadata and data")
    if debug > 0
        println("$ds Ctd() END")
    end
    ctd
end # as_Ctd(salinity, ...)

"""
    plotProfile(ctd::Ctd, which="CT"; vertical="pressure", abbreviate=false,
        legend=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
        debug=false, kwargs...)

Plot an oceanographic profile for data contained in `ctd`, showing how the
variable named by `which` depends on pressure.  The variable is drawn on the x
axis and pressure on the y axis. Following oceanographic convention, pressure
increases downwards on the page and the "x" axis is drawn at the top. The
permitted values of `which` are
`"CT"` for Conservative Temperature,
`"N2"` for N², the square of the buoyancy frequency,
`"S"` for Practical Salinity,
`"SA"` for Absolute Salinity,
`"sigma0"` for the TEOS10 formulation of density anomaly referenced to the surface,
`"spiciness0"` for seawater spiciness referenced to the surface,
and
`"T"` for in-situ temperature.

The default Julia font sizes on axes are overridden in this function, with
8-point being used for both the numbers on axes (`tickfontize`) and the names
of axes (`labelfontsize`).  (The `tickfontsize` matches the Julia default,
but the `labelfontsize` is smaller than the Julia default. The idea is to
not waste space with fonts that are larger than what journals require.)

The `kwargs...` argument is used for arguments to be sent to `plot()`.  For
example, the default way to display the profile diagram is constructed with a
blue line connecting points, but using e.g.
```julia-repl
plotProfile(ctd, "SA", seriestype=:scatter, seriescolor=:red)
```
yields red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on the many plotting controls available in Julia.

# Examples
```julia-repl
using OceanAnalysis, Plots
# Read an Argo file
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = readArgo(f, 1);
# Plot profiles of Conservative Temperature, Absolute Salinity, and potential
# density anomaly with respect to surface pressure.
p1 = plotProfile(d, "CT")
p2 = plotProfile(d, "SA")
p3 = plotProfile(d, "sigma0")
plot(p1, p2, p3, layout=(1, 3), size=(800, 400))
```

See also the [`plotTS`](@ref) function.
"""
function plotProfile(ctd::Ctd, which::String="CT"; vertical::String="pressure", abbreviate::Bool=false,
    legend::Bool=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
    debug::Int64=0, kwargs...)
    ds = debug_space(debug)
    if debug > 0
        println("$ds plotProfile(ctd, '$which') START")
    end
    dataNames = names(ctd.data)
    plotNames = dataNames[dataNames.!="pr".&&dataNames.!="pressure"]
    if !(which in plotNames)
        error("plotProfile() cannot handle which='$which'; try one of: $plotNames")
    end
    S = ctd.data.salinity
    T = ctd.data.temperature
    p = ctd.data.pressure
    # Computing things as below is fast in Julia, so we do it even if the user
    # doesn't actually want SA or the other TEOS-10 variable.  And, I think in
    # many cases, the user *will* want those TEOS-10 things.
    SA = ctd.data.SA #gsw_sa_from_sp.(S, p, ctd.longitude, ctd.latitude)
    CT = ctd.data.CT #gsw_ct_from_t.(SA, T, p)
    sigma0 = ctd.data.sigma0 #gsw_sigma0.(SA, CT)
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
    if which == "T" || which == "CT"
        if debug > 0
            println("$ds     about to plot $which")
        end
        rval = plot(which == "CT" ? CT : T, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if (abbreviate)
                which == "CT" ? "CT[°C]" : "T [°C]"
            else
                which == "CT" ? "Conservative Temperature [°C]" : "Temperature [°C]"
            end,
            yrot=90; kwargs...)
    elseif which == "S" || which == "SA"
        if debug > 0
            println("$ds     about to plot $which")
        end
        rval = plot(which == "SA" ? SA : S, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if (abbreviate)
                which == "SA" ? "SA [g/kg]" : "S"
            else
                which == "SA" ? "Absolute Salinity [g/kg]" : "Practical Salinity"
            end,
            yrot=90; kwargs...)
    elseif which == "sigma0" # gsw formulation
        if debug > 0
            println("$ds     about to plot $which")
        end
        rval = plot(sigma0, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if abbreviate
                "σ₀ [kg/m³]"
            else
                "Potential Density Anomaly, σ₀ [kg/m³]"
            end,
            yrot=90; kwargs...)
    elseif which == "spiciness0" # gsw formulation
        if debug > 0
            println("$ds     about to plot $which")
        end
        rval = plot(gsw_spiciness0.(SA, CT), y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if abbreviate
                "π [kg/m³]"
            else
                "Spiciness [kg/m³]"
            end,
            yrot=90; kwargs...)
    elseif which == "N2"
        if debug > 0
            println("$ds     about to plot $which")
        end
        rval = plot(getElement(ctd, "N2"), y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, framestyle=:box,
            legend=legend, color=:black, gridstyle=:dash, tickfontsize=tickfontsize, labelfontsize=labelfontsize,
            xlabel=if abbreviate
                "N²" # N2" #"N²"
            else
                "N² [s⁻²]" # "N2 [1/s^2]"
            end,
            yrot=90; kwargs...)
    else
        error("Unrecognized 'which'=\"$(which)\". Try 'CT', 'N2', 'S', 'SA', 'sigma0', 'spiciness0', or 'T'.")
    end
    if debug > 0
        println("$ds plotProfile() END")
    end
    rval
end

"""
    plotTS(ctd::Ctd; drawFreezing=true, drawSpiciness=false, abbreviate=false,
        legend=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8;
        debug=false, kwargs...,)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.
Contours of σ₀ are shown with dotted lines.  If `drawFreezing` is true, then
the freezing-point curve is added, with a dashed blue line type.

The `kwargs...` argument is used to represent other arguments that will be sent
to `plot()`.  For example, the default way to display the TS diagram is
constructed with a blue line connecting TS values, but using e.g.

    plotTS(ctd, seriestype=:scatter, seriescolor=:red)

will use red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on such issues.

# Examples
```julia-repl
using OceanAnalysis, Plots
# Read an Argo file
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = readArgo(f, 1);
# Plot TS diagram, using TEOS-10 variables.
plotTS(d)
```

See also [`plotProfile`](@ref).
"""
function plotTS(ctd::Ctd; drawFreezing=true, drawSpiciness=false, abbreviate=false,
    legend=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
    debug::Int64=0, kwargs...)
    ds = debug_space(debug)
    println("$ds plotTS() START")
    S = ctd.data.salinity
    T = ctd.data.temperature
    p = ctd.data.pressure
    lon = ctd.metadata["longitude"]
    lat = ctd.metadata["latitude"]
    SA = gsw_sa_from_sp.(S, p, lon, lat)
    CT = gsw_ct_from_t.(SA, T, p)
    # We start with the measurements ... 
    if debug > 0
        println("$ds     drawing data")
    end
    rval = plot(SA, CT, legend=legend,
        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
        ylabel=abbreviate ? "C [°C]" : "Conservative Temperature [°C]",
        framestyle=:box, yrot=90,
        gridstyle=gridstyle, color=color, tickfontsize=tickfontsize, labelfontsize=labelfontsize; kwargs...)
    # ... then add density contours ...
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    if debug > 0
        println("$ds     adding sigma0 contours")
    end
    contour!(SAc, CTc, (SAc, CTc) -> gsw_sigma0(SAc, CTc), color=:gray84, linewidth=0.5,
        levels=range(22, 30, step=0.2),
        cbar=false, clabels=true)
    # ... then (optionally) add spiciness contours ...
    if drawSpiciness
        if debug > 0
            println("$ds     adding spiciness0 contours")
        end
        contour!(SAc, CTc, (SAc, CTc) -> gsw_spiciness0(SAc, CTc), color=:gray74, linewidth=0.5,
            levels=range(-10, 10, step=0.2),
            cbar=false, clabels=true)
    end
    # ... and finally (optionally) add a freezing-temperature line.
    if drawFreezing
        if debug > 0
            println("$ds     adding freezing line")
        end
        pf = 0.0 # let user specify this?
        SAf = range(xlim[1], xlim[2], length=100)
        saturation_fraction = 0.0
        CTf = gsw_ct_freezing.(SAf, pf, saturation_fraction)
        plot!(xlim=xlim, ylim=ylim)
        plot!(SAf, CTf, color=:blue, linewidth=0.5, linestyle=:dash)
    end
    println("$ds plotTS() END")
    rval
end # plotTS()

"""
    readArgo(filename, column=1)

Read an Argo file and return a Ctd object.  As of 2025-08-23, this code is
still in rapid development; please report problems as issues on
<www.github.com/dankelley/OceanAnalysis.jl/issues>.

# Examples
```julia-repl
using OceanAnalysis, Plots
# Read an Argo file and plot a profile of Absolute Salinity
# (black) and Practical Salinity (red).
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = readArgo(f)
plotTS(d)
```
"""
function readArgo(filename, column=1; debug::Int64=0)
    d = NCDataset(filename, "r")
    ds = debug_space(debug)
    if debug > 0
        println("$ds readArgo() START")
        println("$ds     opened file '$filename' successfully")
    end
    p = convert(Vector{Float64}, d["PRES"][:, column])
    if debug > 0
        println("$ds     p length: ", length(p))
    end
    S = convert(Vector{Float64}, d["PSAL"][:, column])
    if debug > 0
        println("$ds     S length: ", length(S))
    end
    T = convert(Vector{Float64}, d["TEMP"][:, column])
    if debug > 0
        println("$ds     T length: ", length(T))
    end
    lon = convert(Float64, d["LONGITUDE"][1])
    if debug > 0
        println("$ds     lon: $lon")
    end
    lat = convert(Float64, d["LATITUDE"][1])
    if debug > 0
        println("$ds     lat: $lat")
        println("$ds     about to call as_Ctd() ...")
    end
    rval = as_Ctd(S, T, p, lon, lat, debug - 1)
    if debug > 0
        println("$ds readArgo() END")
    end
    rval
end


"""
    ctd = readCtdCNV(filename)

Read a CTD file named `filename` that is in SeaBird CNV format. This returns
`header` (a vector of strings, one per line from the start down to a line
containing `#END`), `metadata` (a Dict with some items scanned from the header)
and `data` (a `dataFrame` holding the data). Note that the column names in
`data` are taken from the CNV file, so the user will need to have some
familiarity with the SeaBird conventions; for example, notice how a temperature
is converted from the T68 scale to the T90 scale, which is required by other
oceanographic software, especially the `gsw` package.

# Examples
```julia-repl
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "ctd.cnv")
header, metadata, data = readCtdCNV(f);
ctd = Ctd(data.sal00, data.t090, data.pr,
    metadata["longitude"], metadata["latitude"]);
p1 = plotProfile(ctd, "SA")
p2 = plotProfile(ctd, "CT")
p3 = plotTS(ctd)
plot(p1, p2, p3, layout=(1, 3))
```
"""
function readCtdCNV(filename::String; debug::Int64=0)
    open(filename) do file
        readCtdCNV(file, debug=debug)
    end
end

function readCtdCNV(stream::IOStream; debug::Int64=0)
    ds = debug_space(debug)
    if debug > 0
        println("$ds readCtdCNV(stream, ...) START")
    end
    lines = readlines(stream)
    header = ""
    dataStart = 0
    dataNames = Vector{String}()
    metadata = Dict{String,Any}()
    for i in eachindex(lines)
        line = chomp(lines[i])
        if occursin(r"^# name ", line)
            tokens = split(line)
            name = replace(tokens[5], ":" => "")
            push!(dataNames, name)
        end
        if occursin(r"^\*\*.*:", line)
            tokens = split(line, ":")
            item = lowercase(replace(tokens[1], "** " => ""))
            value = replace(tokens[2], r"^ *" => "")
            if occursin(r"^longitude", item) || occursin(r"^latitude", item)
                value = coordinateFromString(value)
            end
            metadata[item] = value
        end
        if occursin(r"^\*END\*$", line)
            dataStart = i + 1
            header = lines[1:i]
            break
        end
    end
    if dataStart == 0
        error("This file has no *END* line, so columns cannot be identified")
    end
    if length(dataNames) == 0
        error("No '# name' lines in header, so columns cannot be identifed")
    end
    ncols = length(split(lines[dataStart]))
    if ncols != length(dataNames)
        error("ncols=$ncols does not match length(dataNames)=$(length(dataNames))")
    end
    nrows = length(lines) - dataStart + 1
    if debug > 0
        println("$ds     datanames: $dataNames")
        println("$ds     about to read nrows=$(nrows), ncols=$(ncols)")
    end
    data = Array{Float64,2}(undef, nrows, ncols)
    irow = 1
    for i in dataStart:length(lines)
        d = parse.(Float64, split(lines[i]))
        data[irow, :] = d
        irow = irow + 1
    end
    data = DataFrame(data, dataNames)
    # Add standard columns
    if debug > 0
        println("$ds     adding columns with standard names (e.g. 'pressure' for 'pr')")
    end
    if "pr" in names(data)
        data.pressure = data.pr
    else
        error("No 'pr' column in CNV file; available names are ", names(data))
    end
    if "sal00" in names(data)
        data.salinity = data.sal00
    else
        error("No 'sal00' column in CNV file; available names are ", names(data))
    end
    if "t068" in dataNames
        data.temperature = T90fromT68.(data.t068)
    elseif "t090" in dataNames
        data.temperature = data.t090
    else
        error("No 't068' column in CNV file; available names are ", names(data))
    end
    if debug > 0
        println("$ds     adding SA, CT, sigma0 and spiciness0")
    end
    data.SA = gsw_sa_from_sp.(data.salinity, data.pressure, metadata["longitude"], metadata["latitude"])
    data.CT = gsw_ct_from_t.(data.SA, data.temperature, data.pressure)
    data.sigma0 = gsw_sigma0.(data.SA, data.CT)
    data.spiciness0 = gsw_spiciness0.(data.SA, data.CT)
    metadata["header"] = header
    if debug > 0
        println("$ds     combining metadata and data into a Ctd object")
    end
    rval = Ctd(metadata, data)
    if debug > 0
        println("$ds readCtdCNV() END")
    end
    rval
end

"""
    T90 = T90fromT68(T68::Float64)

Convert a temperature from the T68 scale to the T90 scale.

See also [`T90fromT48`](@ref).
"""
T90fromT68(T48::Float64) = T48 / 1.00024
#T90fromT68(T48::Vector{Float64}) = T48 ./ 1.00024

"""
    T90 = T90fromT48(T48::Float64)

Convert a temperature from the T48 scale to the T90 scale.

See also [`T90fromT68`](@ref).
"""
T90fromT48(T48::Float64) = (T48 - 4.4e-6 * T48 * (100.0 - T48)) / 1.00024
#T90fromT48(T48::Vector{Float64}) = (T48 .- 4.4e-6 .* T48 .* (100.0 .- T48)) ./ 1.00024

"""
    getElement(ctd::Ctd, name::String; debug)

Get an element from a Ctd object.
"""
function getElement(o::Ctd, name::String; debug::Int64=0)
    ds = debug_space(debug)
    if debug > 0
        println("$ds getElement([Ctd object], name=$name) START")
    end
    # Handle values stored directly in Ctd objects
    nameSymbol = Symbol(name)
    if nameSymbol in fieldnames(Ctd)
        return copy(getproperty(o, nameSymbol))
    end
    # Handle items computable via functions of Ctd objects
    if name == "N2"
        return copy(N2(o))
    end
    # Handle TEOS10 variables
    local SA = gsw_sa_from_sp.(o.salinity, o.pressure, o.longitude, o.latitude)
    if name == "SA"
        return copy(SA)
    end
    local CT = gsw_ct_from_t.(SA, o.temperature, o.pressure)
    if name == "CT"
        return copy(CT)
    end
    if name == "sigma0"
        return copy(gsw_sigma0.(SA, CT))
    elseif name == "spiciness0"
        return copy(gsw_spiciness0.(SA, CT))
    end
    # The item is not handled, so return an empty result
    return Nothing
end

"""
    N2(ctd::Ctd, s::Float64=0.15; debug)

Compute N², the square of the buoyancy frequency, for a Ctd object, e.g.
created by either the [`Ctd`](@ref) or [`readArgo`](@ref) function.  The value
is inferred from a cubic spline fitted to sigma0 as a function of pressure.

Smoothing is the tricky part of the analysis.  In the present version, it is
done with the `Dierckx::Spline1D()` function (Reference 1), which is called
with equal weights, `w`, for all points, with `k=3` to set the polynomial order
to cubic, and with `bc="nearest"` to control what happens near boundaries. The
user has no control over these things, although this might change in a future
version of `N2()`.

The user's control rests in `s`, a smoothing parameter that is passed to
`Dierckx:Spline1D()`. If not specified by the user, this defaults to a value
that yields N² curves that are similar to those computed with a default call to
`swN2()` in the `oce` R package.  Users may elect to use larger `s` values for
smoother curves, or smaller ones to get more detail.  It would be a mistake not
to pair experiments with `s` values with plots. As a start, it might be useful
to examine Reference 2, which compares the R and Julia results.

# References

1. https://github.com/JuliaMath/Dierckx.jl
2. https://github.com/dankelley/OceanAnalysis.jl/issues/13

"""
function N2(o::Ctd, s::Float64=0.15; debug::Int64=0)
    ds = debug_space(debug)
    if debug > 0
        println("$ds N2([Ctd object]) START")
    end
    pressure = o.data.pressure
    sigma0 = o.data.sigma0
    i = sortperm(pressure)
    ok = diff(pressure[i]) .> 0.0
    ok = [ok[1]; ok]
    if debug > 0
        println("$ds ok length: ", length(ok))
    end
    j = i[ok]
    local spline = Spline1D(pressure[j], sigma0[j], w=ones(sum(ok)), k=3, bc="nearest", s=s)
    sigma0p = evaluate(spline, pressure)
    rho0 = 1000.0 + mean(sigma0p)
    g = 9.8
    deriv = derivative(spline, pressure)
    N2 = (g / rho0) * deriv
    if debug > 0
        println("$ds  N2 length: ", length(N2))
        println("$ds N2() END")
    end
    return N2
end


end # module OceanAnalysis
