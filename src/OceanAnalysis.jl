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
export as_ctd
export coordinate_from_string
export get_element
export N2
export plot_profile
export plot_TS
export pretty
export read_argo
export read_ctd_cnv
export T90_from_T48
export T90_from_T68

abstract type Oce end

struct Ctd <: Oce
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

function oad(debug::Int64=0, args...)
    if debug > 0
        print(repeat("    ", debug - 1))
        for arg in args
            print(arg)
        end
        print("\n")
    end
end

"""
Calculate sub-intervals with 125 scaling, as in R function of same name

This is needed because contour() in Julia (Reference 1) does not use
simple numbers for auto-computed levels.

# Examples
```julia-repl
# Example that could come up in a TS diagram, where the
# first argument is a range of sigma0 values for the plot.
pretty([22.299, 25.091])
```

# References

1. <https://github.com/JuliaGeometry/Contour.jl/blob/daad6eb0b1464dbc7e824bf8384cad54a3b76445/src/Contour.jl#L100>)
"""
function pretty(x, n=5; debug::Bool=false)
    min, max = extrema(x)
    dx = (max - min) / n
    fac = 10^floor(log10(dx))
    dx0 = dx / fac # dx0 should be between 1 and 10
    if !(1.0 <= dx0 <= 10.0)
        error("dx0 = $dx0 is not between 1.0 and 10.0")
    end
    if 0.0 <= dx0 < 1.5
        dx00 = 1.0
    elseif 1.5 <= dx0 < 3.5
        dx00 = 2.0
    elseif 3.5 <= dx0 < 7.5
        dx00 = 5.0
    else
        dx00 = 10.0
    end
    dxnew = dx00 * fac
    # round() cleans up trailing-digits error
    minnew = round(dxnew * floor(min / dxnew), sigdigits=5)
    maxnew = minnew + dxnew * ceil((max - minnew) / dxnew)
    if debug
        println("fac:$fac, dx:$dx, dxnew:$dxnew, min:$min, minnew:$minnew, max:$max, maxnew:$maxnew")
    end
    rval = collect(range(minnew, maxnew, step=dxnew))
    println(rval)
    println(typeof(rval))
    return rval
end


"""
    degree = coordinate_from_string(s::String)

Try to extract a longitude or latitude from a string. If there are two
(space-separated) tokens in the string, the first is taken as the decimal
degrees, and the second as decimal minutes. The goal is to parse hand-entered
strings, which might contain letters like `"W"` and `"S"` (or the same
in lower case) to indicate the hemisphere. Humans are quite good at writing
confusing strings, so this function is not always helpful.

# Examples
```julia-repl
coordinate_from_string("1.5")   # 1.5
coordinate_from_string("1 30")  # 1.5
coordinate_from_string("1S 30") # -1.5
```
"""
function coordinate_from_string(s::String)
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
function as_ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64},
    longitude::Float64=-30.0, latitude::Float64=30.0;
    debug::Int64=0)
    oad(debug, "as_ctd(<ctd>, debug=$debug) START")
    oad(debug, "    salinity length: $(length(salinity))")
    oad(debug, "    temperature length: $(length(temperature))")
    oad(debug, "    pressure length: $(length(pressure))")
    oad(debug, "    longitude length: $(length(longitude))")
    oad(debug, "    latitude length: $(length(latitude))")
    local SA = gsw_sa_from_sp.(salinity, pressure, longitude, latitude)
    oad(debug, "    SA length: $(length(SA))")
    local CT = gsw_ct_from_t.(SA, temperature, pressure)
    oad(debug, "    CT length: $(length(CT))")
    spiciness0 = gsw_spiciness0.(SA, CT)
    oad(debug, "    spiciness0 length: $(length(spiciness0))")
    sigma0 = gsw_sigma0.(SA, CT)
    oad(debug, "    sigma0 length: $(length(sigma0))")
    oad(debug, "    assembling metadata")
    metadata = Dict{String,Any}()
    metadata["longitude"] = longitude
    metadata["latitude"] = latitude
    oad(debug, "    assembling data")
    data = DataFrame(salinity=salinity, temperature=temperature,
        pressure=pressure, SA=SA, CT=CT, sigma0=sigma0, spiciness0=spiciness0)
    oad(debug, "    creating Ctd object")
    rval = Ctd(metadata, data)
    oad(debug, "    END as_ctd()")
    rval
end # as_ctd(salinity, ...)

"""
    plot_profile(ctd::Ctd, which="CT"; vertical="pressure", abbreviate=false,
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
plot_profile(ctd, "SA", seriestype=:scatter, seriescolor=:red)
```
yields red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on the many plotting controls available in Julia.

# Examples
```julia-repl
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
    legend::Bool=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
    debug::Int64=0, kwargs...)
    oad(debug, "plot_profile(<ctd>, '$which') START")
    data_names = names(ctd.data)
    plot_names = data_names[data_names.!="pr".&&data_names.!="pressure"]
    if !(which in plot_names)
        error("plot_profile() cannot handle which='$which'; try one of: $plot_names")
    end
    oad(debug, "    assembling data")
    S = ctd.data.salinity
    T = ctd.data.temperature
    p = ctd.data.pressure
    # Computing things as below is fast in Julia, so we do it even if the user
    # doesn't actually want SA or the other TEOS-10 variable.  And, I think in
    # many cases, the user *will* want those TEOS-10 things.
    SA = ctd.data.SA #gsw_sa_from_sp.(S, p, ctd.longitude, ctd.latitude)
    CT = ctd.data.CT #gsw_ct_from_t.(SA, T, p)
    sigma0 = ctd.data.sigma0 #gsw_sigma0.(SA, CT)
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
    if which == "T" || which == "CT"
        oad(debug, "    drawing $which")
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
        oad(debug, "    drawing $which")
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
        oad(debug, "    drawing $which")
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
        oad(debug, "    drawing $which")
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
        oad(debug, "    drawing $which")
        rval = plot(get_element(ctd, "N2"), y, ylabel=ylabel,
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
    oad(debug, "    END plot_profile()")
    rval
end

"""
    plot_TS(ctd::Ctd; drawFreezing=true, drawSpiciness=false, abbreviate=false,
        legend=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8;
        debug=false, kwargs...,)

Plot an oceanographic TS diagram, with the Gibbs Seawater equation of state.
Contours of σ₀ are shown with dotted lines.  If `drawFreezing` is true, then
the freezing-point curve is added, with a dashed blue line type.

The `kwargs...` argument is used to represent other arguments that will be sent
to `plot()`.  For example, the default way to display the TS diagram is
constructed with a blue line connecting TS values, but using e.g.

    plot_TS(ctd, seriestype=:scatter, seriescolor=:red)

will use red-filled circles, instead; see https://docs.juliaplots.org/stable/ for
more on such issues.

# Examples
```julia-repl
using OceanAnalysis, Plots
# Read an Argo file
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
d = read_argo(f, 1);
# Plot TS diagram, using TEOS-10 variables.
plot_TS(d)
```

See also [`plot_profile`](@ref).
"""
function plot_TS(ctd::Ctd; draw_freezing=true, draw_spiciness=false,
    sigma0_levels=[],
    abbreviate=false,
    legend=false, color=:black, gridstyle=:dash, tickfontsize=8, labelfontsize=8,
    debug::Int64=0, kwargs...)
    oad(debug, "plot_TS(<ctd>) START")
    S = ctd.data.salinity
    T = ctd.data.temperature
    p = ctd.data.pressure
    lon = ctd.metadata["longitude"]
    lat = ctd.metadata["latitude"]
    SA = gsw_sa_from_sp.(S, p, lon, lat)
    CT = gsw_ct_from_t.(SA, T, p)
    # We start with the measurements ... 
    oad(debug, "    drawing data")
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
    oad(debug, "    drawing sigma0 contours")
    sigma0c = gsw_sigma0.(SAc', CTc)
    println("size(sigma0c) $(size(sigma0c))")
    println("pretty(sigma0c) $(pretty(sigma0c))")
    levels = length(sigma0_levels) > 0 ? sigma0_levels : pretty(sigma0c)
    println("1 levels $(levels)")
    levels = [levels]
    println("2 levels $(levels)")

    contour!(SAc, CTc, sigma0c, color=:gray50, linewidth=1.0, levels=levels,
        cbar=false, clabels=true)
    # ... then (optionally) add spiciness contours ...
    if draw_spiciness
        oad(debug, "    drawing spiciness0 contours")
        contour!(SAc, CTc, (SAc, CTc) -> gsw_spiciness0(SAc, CTc), color=:gray74, linewidth=0.5,
            levels=range(-10, 10, step=0.2),
            cbar=false, clabels=true)
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
    oad(debug, "    END plot_TS()")
    rval
end # plot_TS()

"""
    read_argo(filename, column=1)

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
d = read_argo(f)
plot_TS(d)
```
"""
function read_argo(filename, column=1; debug::Int64=0)
    oad(debug, "read_argo(<filename>, column=$column, debug=$debug) START")
    d = NCDataset(filename, "r")
    pressure = convert(Vector{Float64}, d["PRES"][:, column])
    oad(debug, "    pressure length: $(length(pressure))")
    salinity = convert(Vector{Float64}, d["PSAL"][:, column])
    oad(debug, "    salinity length: $(length(salinity))")
    temperature = convert(Vector{Float64}, d["TEMP"][:, column])
    oad(debug, "    temperature length: $(length(temperature))")
    longitude = convert(Float64, d["LONGITUDE"][1])
    oad(debug, "    longitude: $longitude")
    latitude = convert(Float64, d["LATITUDE"][1])
    oad(debug, "    latitude: $latitude")
    rval = as_ctd(salinity, temperature, pressure, longitude, latitude,
        debug=debug > 0 ? debug + 1 : 0)
    oad(debug, "    END read_argo()")
    rval
end # read_argo()


"""
    ctd = read_ctd_cnv(filename)

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
filename = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(filename)
p1 = plot_profile(ctd, "SA")
p2 = plot_profile(ctd, "CT")
p3 = plot_TS(ctd)
plot(p1, p2, p3, layout=(1, 3))
```
"""
function read_ctd_cnv(filename::String; debug::Int64=0)
    open(filename) do file
        read_ctd_cnv(file, debug=debug)
    end
end

function read_ctd_cnv(stream::IOStream; debug::Int64=0)
    oad(debug, "read_ctd_cnv(stream, ...) START")
    lines = readlines(stream)
    header = ""
    data_start = 0
    data_names = Vector{String}()
    metadata = Dict{String,Any}()
    for i in eachindex(lines)
        line = chomp(lines[i])
        if occursin(r"^# name ", line)
            tokens = split(line)
            name = replace(tokens[5], ":" => "")
            push!(data_names, name)
        end
        if occursin(r"^\*\*.*:", line)
            tokens = split(line, ":")
            item = lowercase(replace(tokens[1], "** " => ""))
            value = replace(tokens[2], r"^ *" => "")
            if occursin(r"^longitude", item) || occursin(r"^latitude", item)
                value = coordinate_from_string(value)
            end
            metadata[item] = value
        end
        if occursin(r"^\*END\*$", line)
            data_start = i + 1
            header = lines[1:i]
            break
        end
    end
    if data_start == 0
        error("This file has no *END* line, so columns cannot be identified")
    end
    if length(data_names) == 0
        error("No '# name' lines in header, so columns cannot be identifed")
    end
    ncols = length(split(lines[data_start]))
    if ncols != length(data_names)
        error("ncols=$ncols does not match length(data_names)=$(length(data_names))")
    end
    nrows = length(lines) - data_start + 1
    oad(debug, "    datanames: $data_names")
    oad(debug, "    reading nrows=$(nrows), ncols=$(ncols)")
    data = Array{Float64,2}(undef, nrows, ncols)
    irow = 1
    for i in data_start:length(lines)
        d = parse.(Float64, split(lines[i]))
        data[irow, :] = d
        irow = irow + 1
    end
    data = DataFrame(data, data_names)
    # Add standard columns
    oad(debug, "    adding columns with standard names (e.g. 'pressure' for 'pr')")
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
    if "t068" in data_names
        data.temperature = T90_fromT_68.(data.t068)
    elseif "t090" in data_names
        data.temperature = data.t090
    else
        error("No 't068' column in CNV file; available names are ", names(data))
    end
    oad(debug, "    adding columns for SA, CT, sigma0 and spiciness0")
    data.SA = gsw_sa_from_sp.(data.salinity, data.pressure, metadata["longitude"], metadata["latitude"])
    data.CT = gsw_ct_from_t.(data.SA, data.temperature, data.pressure)
    data.sigma0 = gsw_sigma0.(data.SA, data.CT)
    data.spiciness0 = gsw_spiciness0.(data.SA, data.CT)
    metadata["header"] = header
    oad(debug, "    combining metadata and data into a Ctd object")
    rval = Ctd(metadata, data)
    oad(debug, "    END read_ctd_cnv()")
    rval
end

"""
    T90 = T90_from_T68(T68::Float64)

Convert a temperature from the T68 scale to the T90 scale.

See also [`T90_from_T48`](@ref).
"""
T90_from_T68(T48::Float64) = T48 / 1.00024
#T90fromT68(T48::Vector{Float64}) = T48 ./ 1.00024

"""
    T90 = T90_from_T48(T48::Float64)

Convert a temperature from the T48 scale to the T90 scale.

See also [`T90_from_T68`](@ref).
"""
T90_from_T48(T48::Float64) = (T48 - 4.4e-6 * T48 * (100.0 - T48)) / 1.00024
#T90fromT48(T48::Vector{Float64}) = (T48 .- 4.4e-6 .* T48 .* (100.0 .- T48)) ./ 1.00024

"""
    get_element(ctd::Ctd, name::String; debug)

Get an element from a Ctd object.
"""
function get_element(o::Ctd, name::String; debug::Int64=0)
    oad(debug, "get_element([Ctd object], name=$name) START")
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
created by either the [`Ctd`](@ref) or [`read_argo`](@ref) function.  The value
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
    oad(debug, "N2([Ctd object]) START")
    pressure = o.data.pressure
    sigma0 = o.data.sigma0
    i = sortperm(pressure)
    ok = diff(pressure[i]) .> 0.0
    ok = [ok[1]; ok]
    oad(debug, "    ok length: $(length(ok))")
    j = i[ok]
    local spline = Spline1D(pressure[j], sigma0[j], w=ones(sum(ok)), k=3, bc="nearest", s=s)
    sigma0p = evaluate(spline, pressure)
    rho0 = 1000.0 + mean(sigma0p)
    g = 9.8
    deriv = derivative(spline, pressure)
    N2 = (g / rho0) * deriv
    oad(debug, "    N2 length: $(length(N2))")
    oad(debug, "    END N2()")
    return N2
end


end # module OceanAnalysis
