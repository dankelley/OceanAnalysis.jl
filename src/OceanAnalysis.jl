module OceanAnalysis

using NCDatasets
using DataFrames
using GibbsSeaWater
using Plots
using CSV

# Structs
export Oce
export Ctd
#. export Argo

# Functions
export Ctd
export coordinateFromString
export getElement
export plotProfile
export plotTS
export readArgo
export readCtdCNV
export T90fromT48
export T90fromT68

abstract type Oce end

struct Ctd <: Oce
    salinity::Vector{Float64}
    temperature::Vector{Float64}
    pressure::Vector{Float64}
    longitude::Float64
    latitude::Float64
    SA::Vector{Float64}
    CT::Vector{Float64}
    sigma0::Vector{Float64}
    spiciness0::Vector{Float64}
end

#.struct Argo <: Ctd
#.    filename::String
#.end

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
    Ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64}, longitude::Float64=-30, latitude::Float64=30)

Construct a `Ctd` structure, given vectors Practical Salinity, in-situ
Temperature, and sea pressure, along with single numbers indicating longitude
and latitude. Note that the last two are needed for the computation of Absolute
Salinity, Conservative Temperature, sigma0 and spicines0, all of which are
which are stored in the returned value alongside the three supplied vectors.

"""
# Convenience function, which carries out TEOS-10 computations
function Ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64}, longitude::Float64=-30.0, latitude::Float64=30.0)
    SA = gsw_sa_from_sp.(salinity, pressure, longitude, latitude)
    CT = gsw_ct_from_t.(SA, temperature, pressure)
    spiciness0 = gsw_spiciness0.(SA, CT)
    sigma0 = gsw_sigma0.(SA, CT)
    Ctd(salinity, temperature, pressure, longitude, latitude, SA, CT, sigma0, spiciness0)
end

"""
    plotProfile(ctd::Ctd; which::String="CT", vertical="pressure", legend=false, abbreviate=false, debug::Bool=false, kwargs...)

Plot an oceanographic profile for data contained in `ctd`, showing how the
variable named by `which` depends on pressure.  The variable is drawn on the x
axis and pressure on the y axis. Following oceanographic convention, pressure
increases downwards on the page and the "x" axis is drawn at the top. The
permitted values of `which` are `"T"` for in-situ temperature, `"CT"` for
Conservative Temperature, `"S"` for Practical Salinity, `"SA"` for Absolute
Salinity, `"sigma0"` for density anomaly referenced to the surface,in the
TEOS10 formulation, or `"spiciness0"` for seawater spiciness referenced to the
surface. The `seriestype` and other arguments have the same meaning as for
general julia plots, e.g. using `seriestype=:path` joins the data points, and
`seriestype=:scatter` shows a symbol at each point.

The `kwargs...` argument is used to represent other arguments that will be sent
to `plot()`.  For example, the default way to display the profile diagram is
constructed with a blue line connecting points, but using e.g.

    plotProfile(ctd, which="SA", seriestype=:scatter, seriescolor=:red)

will use red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on such issues.

See also [`plotTS`](@ref).
"""
function plotProfile(ctd::Ctd; which::String="CT", vertical="pressure", legend=false, abbreviate=false, debug::Bool=false, kwargs...)
    if debug
        println("in plotProfile(ctd,which=\"$which\")")
    end
    S = ctd.salinity
    T = ctd.temperature
    p = ctd.pressure
    # Computing things as below is fast in Julia, so we do it even if the user
    # doesn't actually want SA or the other TEOS-10 variable.  And, I think in
    # many cases, the user *will* want those TEOS-10 things.
    SA = gsw_sa_from_sp.(S, p, ctd.longitude, ctd.latitude)
    CT = gsw_ct_from_t.(SA, T, p)
    sigma0 = gsw_sigma0.(SA, CT)
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
        plot(which == "CT" ? CT : T, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, legend=legend, framestyle=:box,
            xlabel=if (abbreviate)
                which == "CT" ? "CT[°C]" : "T [°C]"
            else
                which == "CT" ? "Conservative Temperature [°C]" : "Temperature [°C]"
            end,
            yrot=90; kwargs...)
    elseif which == "S" || which == "SA"
        plot(which == "SA" ? SA : S, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, legend=legend, framestyle=:box,
            xlabel=if (abbreviate)
                which == "SA" ? "SA [g/kg]" : "S"
            else
                which == "SA" ? "Absolute Salinity [g/kg]" : "Practical Salinity"
            end,
            yrot=90; kwargs...)
    elseif which == "sigma0" # gsw formulation
        plot(sigma0, y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, legend=legend, framestyle=:box,
            xlabel=if abbreviate
                "σ₀ [kg/m³]"
            else
                "Potential Density Anomaly, σ₀ [kg/m³]"
            end,
            yrot=90; kwargs...)
    elseif which == "spiciness0" # gsw formulation
        plot(gsw_spiciness0.(SA, CT), y, ylabel=ylabel,
            yaxis=:flip, xmirror=true, legend=legend, framestyle=:box,
            xlabel=if abbreviate
                "π [kg/m³]"
            else
                "Spiciness [kg/m³]"
            end,
            yrot=90; kwargs...)
    else
        println("Unrecognized 'which'='$(which). Try 'T', 'CT', 'S', 'SA', 'sigma0' or 'spiciness0'.")
    end
end

"""
    plotTS(ctd::Ctd; drawFreezing=true, drawSpiciness=false, legend=false, abbreviate=false, debug=false, kwargs...,)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.
Contours of σ₀ are shown with dotted lines.  If `drawFreezing` is true, then
the freezing-point curve is added, with a dashed blue line type.

The `kwargs...` argument is used to represent other arguments that will be sent
to `plot()`.  For example, the default way to display the TS diagram is
constructed with a blue line connecting TS values, but using e.g.

    plotTS(ctd, seriestype=:scatter, seriescolor=:red)

will use red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on such issues.

See also [`plotProfile`](@ref).
"""
function plotTS(ctd::Ctd; drawFreezing=true, drawSpiciness=false, legend=false, abbreviate=false, debug::Bool=false, kwargs...)
    if debug
        println("in plotTS(ctd)")
    end
    S = ctd.salinity
    T = ctd.temperature
    p = ctd.pressure
    SA = gsw_sa_from_sp.(S, p, ctd.longitude, ctd.latitude)
    CT = gsw_ct_from_t.(SA, T, p)
    # We start with the measurements ... 
    plot(SA, CT, legend=legend,
        xlabel=abbreviate ? "SA [g/kg]" : "Absolute Salinity [g/kg]",
        ylabel=abbreviate ? "C [°C]" : "Conservative Temperature [°C]",
        framestyle=:box, yrot=90; kwargs...)
    # ... then add density contours ...
    xlim = xlims()
    ylim = ylims()
    SAc = range(xlim[1], xlim[2], length=300)
    CTc = range(ylim[1], ylim[2], length=300)
    contour!(SAc, CTc, (SAc, CTc) -> gsw_sigma0(SAc, CTc), color=:gray, linewidth=0.5,
        levels=range(22, 30, step=0.2),
        cbar=false, clabels=true)
    # ... then (optionally) add spiciness contours ...
    if drawSpiciness
        contour!(SAc, CTc, (SAc, CTc) -> gsw_spiciness0(SAc, CTc), color=:gray, linewidth=0.5,
            levels=range(-10, 10, step=0.2),
            cbar=false, clabels=true)
    end
    # ... and finally (optionally) add a freezing-temperature line.
    if drawFreezing
        pf = 0.0 # let user specify this?
        SAf = range(xlim[1], xlim[2], length=100)
        saturation_fraction = 0.0
        CTf = gsw_ct_freezing.(SAf, pf, saturation_fraction)
        plot!(xlim=xlim, ylim=ylim)
        plot!(SAf, CTf, color=:blue, linewidth=0.5, linestyle=:dash)
    end
end

"""
argo = readArgo(filename, column=1, pmax=10000)

FIXME: when code is stablized (requires real-world testing), write more
docs here.

# Examples
```julia-repl
using OceanAnalysis, Plots
# Read a file (which only exists on author's machine) and plot
# a profile of Absolute Salinity in black ink, with superimposed
# Practical Salinity in red ink.
argo_file = "/Users/kelley/data/argo/D4902911_095.nc"
if isfile(argo_file)
    d = readArgo(argo_file)
    plotProfile(d, which="SA", seriescolor=:black)
    plot!(d.salinity, d.pressure, seriescolor=:red)
end
```
"""
function readArgo(filename, column=1, pmax=10000)
    d = NCDataset(filename, "r")
    p = d["PRES"][:, column]
    look = p .< pmax
    p = convert(Vector{Float64}, p[look])
    S = convert(Vector{Float64}, d["PSAL"][look, column])
    T = convert(Vector{Float64}, d["TEMP"][look, column])
    lon = convert(Float64, d["LONGITUDE"][1])
    lat = convert(Float64, d["LATITUDE"][1])
    Ctd(S, T, p, lon, lat)
end


"""
header, metadata, data = readCtdCNV(filename)

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
header, metadata, data = readCtdCNV("ctd.cnv")
ctd = Ctd(data.sal00,
    T90fromT68(data.t068),
    data.pr,
    metadata["longitude"],
    metadata["latitude"])
plotProfile(ctd, which="SA")
savefig("readcnv_profile_SA.pdf")
plotProfile(ctd, which="CT")
savefig("readcnv_profile_CT.pdf")
plotTS(ctd, which="TS")
savefig("readcnv_TS.pdf")
```
"""
function readCtdCNV(filename::String, debug::Bool=false)
    open(filename) do file
        return readCtdCNV(file, debug)
    end
end

function readCtdCNV(stream::IOStream, debug::Bool=false)
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
        error("ncols=$(ncols) does not match length(dataNames)=$(length(dataNames))")
    end
    nrows = length(lines) - dataStart + 1
    if debug
        println("will try to read nrows=$(nrows), ncols=$(ncols)")
    end
    data = Array{Float64,2}(undef, nrows, ncols)
    irow = 1
    for i in dataStart:length(lines)
        if debug
            println("reading row $(i)")
        end
        d = parse.(Float64, split(lines[i]))
        data[irow, :] = d
        irow = irow + 1
    end
    data = DataFrame(data, dataNames)
    if debug
        println("NOTE: not yet renaming data or parsing units")
    end
    return header, metadata, data
end





"""
    T90 = T90fromT68(T68::Float64)

Convert a temperature from the T68 scale to the T90 scale.

See also [`T90fromT48`](@ref).
"""
T90fromT68(T48::Float64) = T48 / 1.00024
T90fromT68(T48::Vector{Float64}) = T48 ./ 1.00024

"""
    T90 = T90fromT48(T48::Float64)

Convert a temperature from the T48 scale to the T90 scale.

See also [`T90fromT68`](@ref).
"""
T90fromT48(T48::Float64) = (T48 - 4.4e-6 * T48 * (100.0 - T48)) / 1.00024
T90fromT48(T48::Vector{Float64}) = (T48 .- 4.4e-6 .* T48 .* (100.0 .- T48)) ./ 1.00024

# %%
"""
    getElement(ctd, string)
"""
function getElement(o::Ctd, name::String)
    if name == "salinity"
        return o.salinity
    elseif name == "temperature"
        return o.temperature
    elseif name == "pressure"
        return o.pressure
    elseif name == "longitude"
        return o.longitude
    elseif name == "latitude"
        return o.latitude
    end
    SP = o.salinity
    T = o.temperature
    p = o.pressure
    lon = o.longitude
    lat = o.latitude
    SA = gsw_sa_from_sp.(SP, p, lon, lat)
    CT = gsw_ct_from_t.(SA, T, p)
    # it is likely a TEOS10 item
    if name == "SA"
        return (SA)
    elseif name == "CT"
        return (CT)
    elseif name == "spiciness0"
        return (gsw_spiciness0.(SA, CT))
    elseif name == "sigma0"
        return (gsw_sigma0.(SA, CT))
    else
        error("cannot look up $name")
    end
end


end # module OceanAnalysis
