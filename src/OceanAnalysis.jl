"""
The OceanAnalysis module is intended to help with the analysis of oceanographic
data. It is in a preliminary form, providing help with only two file
types: Argo NetCDF files and CTD files in the Seabird CNV format.  In neither
case does it read all the data.  If you need more powerful tools for
reading and analysing oceanographic data, consider using the `oce` package
in the R language, which over a decade old and supports many data types.
"""
module OceanAnalysis

using NCDatasets
using Dates
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
export depth_from_pressure
export fix_gsw_bad_code
export fix_gsw_bad_code!
export get_element
export N2
export plot_profile
export plot_TS
export pressure_from_depth
export pressure_from_z
export pretty
export read_argo
export read_ctd_cnv
export salinity_from_conductivity
export T90_from_T48
export T90_from_T68
export z_from_pressure

abstract type Oce end

"""
    An object to hold CTD data

This is a struct that holds a Dict named `metadata` and a DataFrame named `data`.
"""
struct Ctd <: Oce
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

"""
    Split Argo "id_cycle" into components id and cycle
"""
function argo_id_cycle(idcycle::String="D123_321")
    splitat = firstindex("_", idcycle)[1]
    id = idcycle[1:splitat-1]
    cycle = idcycle[splitat+1:end]
    id, cycle
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
    Change any values of x that equal the GSW 'missing' code (9e15) to NaN

    A copy is returned, with x unaltered.  See [`fix_gsw_bad_code!`](@ref) for an
    in-place version.

"""
function fix_gsw_bad_code(x)
    rval = copy(x)
    bad = rval .> 1e15
    if any(bad)
        rval[bad] .= NaN
    end
    rval
end

"""
    In-place change any values of x that equal the GSW 'missing' code (9e15) to NaN

    This alters x.  See [`fix_gsw_bad_code`](@ref) for a version that does
    not alter x.

"""
function fix_gsw_bad_code!(x)
    bad = x .> 1e15
    if any(bad)
        x[bad] .= NaN
    end
    x
end


"""
    Compute Practical Salinity from conductivity (mS/cm), temperature (degC) and pressure (dbar).
"""
#gsw::gsw_SP_from_C(C0 * conductivity, temperature, pressure)
function salinity_from_conductivity(conductivity::Float64, temperature::Float64, pressure::Float64)
    gsw_sp_from_c(conductivity, temperature, pressure)
end


"""
    Compute sea pressure (dbar) from depth (m) and latitude (deg).
"""
function pressure_from_depth(depth::Float64, latitude::Float64=45.0)
    return gsw_p_from_z(-depth, latitude, 0.0, 0.0)
end

"""
    Compute sea pressure (dbar) from vertical coordinate (m) and latitude (deg).
"""
function pressure_from_z(z::Float64, latitude::Float64=45.0)
    return gsw_p_from_z(z, latitude, 0.0, 0.0)
end

"""
    Compute seawater depth (m) from sea pressure (dbar)
"""
function depth_from_pressure(pressure::Float64, latitude::Float64=45.0)
    return -gsw_z_from_p(pressure, latitude, 0.0, 0.0)
end

"""
    Compute vertical coordinate (m) from sea pressure (dbar)
"""
function z_from_pressure(pressure::Float64, latitude::Float64=45.0)
    return gsw_z_from_p(pressure, latitude, 0.0, 0.0)
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
function pretty(x, n=5; debug::Int64=0)
    min, max = extrema(filter(!isnan, x))
    oad(debug, "pretty() got min=$min and max=$max")
    if max == min
        @warn("pretty() got max=min=$min, so returning empty vector")
        return []
    end
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
    oad(debug, "fac:$fac, dx:$dx, dxnew:$dxnew, min:$min, minnew:$minnew, max:$max, maxnew:$maxnew")
    rval = collect(range(minnew, maxnew, step=dxnew))
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
coordinate_from_string("27* 14.072 N") # 27.234533333333335
coordinate_from_string("111* 31.440 W") # -111.524
```
"""
function coordinate_from_string(s::String)
    # ** Latitude: 27* 14.072 N
    # ** Longitude: 111* 31.440 W
    sign = occursin(r"[wWsS]", s) ? -1.0 : 1.0
    s = replace(s, r"[nNsSeEwW\*]" => "")
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
    as_ctd(salinity, temperature, pressure, longitude=-30.0, latitude=30.0; time, debug=0)

Construct a [`Ctd`](@ref) object, given S, T, p, and a location.

Returns a [`Ctd`](@ref) object with a `data` element that is a data frame holding
the provided water properties, along with computed Absolute Salinity (`SA`)
Conservative Temperature (`CT`), potential density anomaly relative to the
surface pressure (`sigma0`) and spiciness with respect to surface pressure
(`spiciness0`).  The object also holds a `metadata` element that holds
`longitude`, `latitude` and `time`.

# Arguments
- `salinity::Vector{Float64}` measured salinity values, in Practical Salinity units.
- `temperature::Vector{Float64}` measured temperature values, in degrees Celsius.
- `pressure::Vector{Float64}` measured sea pressure, in dbar.
- `longitude::Float64` observation longitude, in degrees East. If not provided, this defaults
    to -30 (i.e. -30E, or 30W, in the North Atlantic).
- `latitude::Float64` observation latitude, in degrees North. If not provided, this defaults
    to 30 (i.e. 30N, in the North Atlantic).
- `time::Date.DateTime` an optional indication of the measurement start time.
- `debug::Int64` an optional value that, if it exceeds 0, indicates that
    debugging output should be printed during processing.

# Examples
```jldoctest
julia> as_ctd([32.],[15.],[0.],-63.,40.)
Ctd(Dict{String, Any}("latitude" => 40.0, "time" => nothing, "longitude" => -63.0), 1×7 DataFrame
 Row │ salinity  temperature  pressure  SA       CT       sigma0   spiciness0
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────
   1 │     32.0         15.0       0.0  32.1516  15.0642  23.6653   0.0686905)
```
"""
function as_ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64},
    longitude::Float64=NaN, latitude::Float64=NaN; time=nothing, debug::Int64=0)
    oad(debug, "as_ctd(<ctd>, debug=$debug) START")
    #oad(debug, "    given salinity (length: $(length(salinity)), max: $(maximum(filter(!isnan, salinity))))")
    oad(debug, "    given salinity of length ", length(salinity), ", which starts: ", first(salinity, 2))
    oad(debug, "    given temperature of length ", length(temperature), ", which starts: ", first(temperature, 2))
    oad(debug, "    given pressure of length ", length(pressure), ", which starts: ", first(pressure, 2))
    oad(debug, "    given longitude:  ", longitude)
    oad(debug, "    given latitude:   ", latitude)
    if ismissing(longitude) || ismissing(latitude) || isnan(longitude) || isnan(latitude)
        lon = -30.0
        lat = 30.0
        @warn("as_ctd() given NaN longitude/latitude values, so SA, CT, etc. computed at -30E, 30N.")
    else
        lon = longitude
        lat = latitude
    end
    local SA = gsw_sa_from_sp.(salinity, pressure, lon, lat) |> fix_gsw_bad_code!
    oad(debug, "    created SA length ", length(SA), ", which starts: ", first(SA, 2))
    local CT = gsw_ct_from_t.(SA, temperature, pressure) |> fix_gsw_bad_code!
    oad(debug, "    created CT of length ", length(CT), ", which starts: ", first(CT, 2))
    sigma0 = gsw_sigma0.(SA, CT) |> fix_gsw_bad_code!
    oad(debug, "    created sigma0 of length ", length(sigma0), ", which starts: ", first(sigma0, 2))
    spiciness0 = gsw_spiciness0.(SA, CT) |> fix_gsw_bad_code!
    oad(debug, "    created spiciness0 of length ", length(spiciness0), ", which starts: ", first(spiciness0, 2))
    oad(debug, "    assembling data (a DataFrame) from the above")
    data = DataFrame(salinity=salinity, temperature=temperature,
        pressure=pressure, SA=SA, CT=CT, sigma0=sigma0, spiciness0=spiciness0)
    oad(debug, "    assembling metadata (a Dict)")
    metadata = Dict{String,Any}()
    # Note that we are inserting the longitude and latitude from the function call,
    # not the -30,30 values that we invented in order to estimate SA, CT, sigma0 and spicines0
    metadata["longitude"] = longitude
    metadata["latitude"] = latitude
    if !ismissing(time)
        metadata["time"] = time
    end
    oad(debug, "    passing metadata and data to Ctd() to construct a return value")
    rval = Ctd(metadata, data)
    oad(debug, "END as_ctd()")
    rval
end # as_ctd()

"""
    plot_profile(ctd::Ctd, which::String="CT"; vertical::String="pressure",
        abbreviate::Bool=false, legend::Bool=false,
        tickfontsize=8, labelfontsize=8, debug::Int64=0, kwargs...)

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
    legend::Bool=false, tickfontsize=8, labelfontsize=8,
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
    SA = ctd.data.SA |> fix_gsw_bad_code!
    CT = ctd.data.CT |> fix_gsw_bad_code!
    sigma0 = ctd.data.sigma0
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
        rval = plot(gsw_spiciness0.(SA, CT) |> fix_gsw_bad_code!,
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

"""
    read_argo(filename, column=1; require_valid=true, debug=0)

Read an Argo file and return a Ctd object that holds salinity, temperature,
pressure (and derived columns) but no other columns from the file.  As of
2025-08-23, this code is still in rapid development; please report problems as
issues on <www.github.com/dankelley/OceanAnalysis.jl/issues>.

If `require_valid` is true (the default) then an error is reported if the file
lacks one of three required data columns, or either longitude or latitude.  An
error is also reported if any of these items consists entirely of missing
values. This is because such files are unlikely to be of much use. In some
cases, setting `require_valid` to false may permit the file to be read, but
this has not been tested, since the results in such cases are not likely to be
of practical use.

Set `debug` to a positive integer to cause `read_argo()` to print messages
during processing. This can be handy if problems arise.

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
function read_argo(filename, column=1; require_valid=true, debug::Int64=0)
    oad(debug, "read_argo(<filename>, column=$column, require_valid=$require_valid, debug=$debug) START")
    local rval = nothing
    NCDataset(filename, "r") do d
        oad(debug, "    about to read salinity, temperature and pressure data.")
        salinity = get_nc_value(d, "PSAL", require_valid)
        oad(debug, "    read ", length(salinity), " salinity values, starting with ",
            first(salinity, 2))
        column_length = length(salinity)
        temperature = get_nc_value(d, "TEMP", require_valid)
        if length(temperature) != column_length
            error("salinity and temperature have different lengths (",
                column_length, " and ", length(temperature), ")")
        end
        oad(debug, "    read ", length(temperature), " temperature values, starting with ",
            first(temperature, 2))
        pressure = get_nc_value(d, "PRES", require_valid)
        if length(pressure) != column_length
            error("salinity and pressure have different lengths (",
                column_length, " and ", length(pressure), ")")
        end
        oad(debug, "    read ", length(pressure), " pressure values, starting with ",
            first(pressure, 2))
        longitude = get_nc_value(d, "LONGITUDE", require_valid)
        if ismissing(longitude)
            @warn("read_argo() found missing longitude")
        end
        oad(debug, "    read longitude: $longitude")
        latitude = get_nc_value(d, "LATITUDE", require_valid)
        if ismissing(latitude)
            @warn("read_argo() found missing latitude")
        end
        oad(debug, "    read latitude: $latitude")
        # Non-numeric items cannot be retrieved with get_nc_value(), so we get
        # them directly.
        time = d["JULD"][1] # NCDatasets converts this to a Date.DateTime for us!
        oad(debug, "    read time: $time")
        rval = as_ctd(salinity, temperature, pressure, longitude, latitude,
            time=time, debug=debug > 0 ? debug + 1 : 0)
        oad(debug, "    extending ctd object .metadata by adding argo-specific items")
        # Do some things directly, because get_nc_value() is designed for numeric items
        if haskey(d, "DATE_CREATION")
            rval.metadata["date_creation"] = DateTime(join(d["DATE_CREATION"]), dateformat"yyyymmddHHMMSS")
        else
            rval.metadata["date_creation"] = missing
        end
        # Some files don't have a DATA_MODE entry, so we set it to blank in that case
        #print(sort(keys(d)))
        if haskey(d, "DATA_MODE")
            #print("ok? ", d["DATA_MODE"][1])
            rval.metadata["data_mode"] = d["DATA_MODE"][1]
        else
            rval.metadata["data_mode"] = "?"
        end
        rval.metadata["filename"] = filename
        # Remove trailing blanks in platform ID code, to avoid user problems with e.g. aggregating cycles
        rval.metadata["platform"] = replace(join(d["PLATFORM_NUMBER"][:, 1]), "missing" => "")
        # I think one cycle can hold may profiles, so we only examine the first CYCLE_NUMBER value
        rval.metadata["cycle"] = d["CYCLE_NUMBER"][1]
    end
    oad(debug, "END read_argo()")
    return rval
end # read_argo()

# """
#     Transform an item from a NetCDF file into a more useable object
# 
#     This converts the item into either a `Float64` object or `Vector{Float64}` object,
#     depending on its length.  Also, values equal to the NetCDF "bad" flag for easier 
#     Values exceeding 1e14 that `ismissing()` finds to be flags
# """
# function get_nc_value(item)
#     bad = ismissing.(item)
#     if any(bad)
#         item[ismissing.(item)] .= NaN
#     end
#     if length(item) > 1
#         rval = convert(Vector{Float64}, item)
#     else
#         rval = convert(Float64, item)
#     end
#     return rval |> fix_gsw_bad_code!
# end

function get_nc_value(d, name, require_valid=true)
    if !(name in keys(d))
        error("this file contains no ", name, " data")
    end
    #println("DAN in get_nc_value() with name='$name'")
    local item = d[name]
    ndim = ndims(item)
    if ndim == 1
        item = item[1]
    elseif ndim == 2
        item = item[:, 1]
    else
        error("ndim of \"$name\" must be 1 or 2, but it is $ndim")
    end
    bad = ismissing.(item)
    if require_valid && all(bad)
        error("the ", name, " field contains no non-missing values")
    end
    if any(bad)
        if all(ismissing.(item))
            return item
        end
        item[ismissing.(item)] .= NaN
    end
    if length(item) > 1
        rval = convert(Vector{Float64}, item)
    else
        rval = convert(Float64, item)
    end
    return rval
end



"""
    ctd = read_ctd_cnv(filename)

Read a CTD file named `filename` that is in SeaBird CNV format.

Returns a [`Ctd`](@ref) object that holds `metadata` (a Dict) and `data` (a
DataFrame). `metadata` item holds `header` (a vector of strings, one per line
from the start down to a line containing `#END`), plus some particular items
scanned from that header. `data` holds the columnar data read from the file,
along with renamed values in standard nomenclature. At present, the only
renamed items are salinity, temperature, and pressure. Note that if the data
file indicates temperature is on the T68 scale, then this is converted
to the standard modern scale, T90, before saving as `temperature`. 

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
        read_ctd_cnv(file, filename; debug=debug)
    end
end

"""
    read_ctd_cnv(stream; debug)
"""
function read_ctd_cnv(stream::IOStream, filename::String=""; debug::Int64=0)
    oad(debug, "read_ctd_cnv(\"", filename, "\", ...) START")
    lines = readlines(stream)
    #oad(debug, "    $(length(lines)) lines in file")
    data_names = Vector{String}()
    oad(debug, "    assembling .metadata (a Dict)")
    metadata = Dict{String,Any}()
    time_format = DateFormat("u d yyy HH:MM:SS")
    # set defaults
    header = ""
    data_start = 0
    time = nothing
    latitude = NaN
    longitude = NaN
    names_start = 0
    names_found = false
    data_start = 0
    latitude = NaN # to catch case where file lacks this info
    longitude = NaN # to catch case where file lacks this info
    for i in eachindex(lines)
        line = lines[i]
        #oad(debug, "examining line: '", line, "'")
        if occursin(r"^# name ", line)
            if !names_found
                names_found = true
                oad(debug, "    NOTE: the names of data columns start at line ", i)
            end
            tokens = split(line)
            name = replace(tokens[5], ":" => "")
            push!(data_names, name)
        elseif occursin(r"^# start_time", line)
            # Do this step by step, to make it easier to find problems if we
            # encounter files in formats that are not currently handled.
            time_string = split(line, " = ")[2]
            oad(debug, "    time_string '", time_string, "'")
            time_string = replace(time_string, r" \[.*$" => "")
            #oad(debug, "time_string '", time_string, "'")
            time_string = strip(time_string)
            #oad(debug, "time_string '", time_string, "'")
            time = DateTime(time_string, time_format)
            oad(debug, "    inferred time=", time)
        elseif occursin(r"^\*.* [Ll]atitude:", line) # e.g. "** Latitude: 74 15.88 N"
            #println("try to decode latitude in ** : format")
            #println("1. line=", line)
            sign = occursin(r"[Ss]", line) ? -1 : 1
            #println("2. sign=", sign)
            line = replace(line, r"[NSns]" => "") |> strip
            #println("3. after remove hemisphere line='", line, "'")
            s = split(line, ": ")[2] |> strip
            s = replace(s, r"\*" => "") # some files have a * (for degree sign, I suppose)
            #println("4. s=", s)
            ss = split(s, r"[ ]+")
            #println("5. ss= ", ss)
            latitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
            oad(debug, "    inferred latitude=", latitude)
        elseif occursin(r"^\*.* [Ll]atitude[ ]*=", line) # e.g. "* NMEA Latitude = 70 33.09 N"
            #println("lat= case")
            #println(line)
            s = split(line, "=")[2]
            #println("s after split: '", s, "'")
            sign = occursin(r"[sS]", s) ? -1 : 1
            #println("sign=", sign)
            s = replace(s, r"[NSns]" => "") |> strip
            #println("Before split for deg and dec-min, s='", s, "'")
            ss = split(s, r"[ ]+")
            #println("after split, ss=", ss)
            latitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
            oad(debug, "    inferred latitude=", latitude)
        elseif occursin(r"^\*.* [Ll]ongitude:", line)
            #println("1. line=", line)
            sign = occursin(r"[Ww]", line) ? -1 : 1
            #println("2. sign=", sign)
            line = replace(line, r"[EWew]" => "") |> strip
            #println("3. after remove hemisphere = ", line)
            s = split(line, ": ")[2] |> strip
            s = replace(s, r"\*" => "") # some files have a * (for degree sign, I suppose)
            #println("4. s=", s)
            ss = split(s, r"[ ]+")
            #println("5. ss= ", ss)
            longitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
            oad(debug, "    inferred longitude=", longitude)
        elseif occursin(r"^\*.* [Ll]ongitude[ ]*=", line) # e.g. "* NMEA Longitude = 132 40.03 W"
            #println(line)
            s = split(line, " = ")[2]
            #println(s)
            sign = occursin(r"[Ww]", s) ? -1 : 1
            #println(sign)
            replace(s, r"[eEwW]" => "")
            #println(s)
            ss = split(s, r"[ ]+")
            longitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
        elseif occursin(r"^\*\*.*:", line)
            #println("line with colon: '$line'")
            tokens = split(line, ":")
            item = lowercase(replace(tokens[1], "** " => ""))
            value = replace(tokens[2], r"^ *" => "")
            metadata[item] = value
        elseif occursin(r"\*END\*", line)
            data_start = i + 1
            oad(debug, "    NOTE: the data columns start at line ", data_start)
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
    metadata["header"] = header
    oad(debug, "    assembling .data (a DataFrame)")
    data = DataFrame(data, data_names, makeunique=true)
    data_names = names(data)
    println("data_names=", data_names)
    println(first(data, 2))
    # Add standard columns
    if "pr" in data_names
        data.pressure = data.pr
    elseif "prdM" in data_names
        data.pressure = data.prdM
    elseif "prDM" in data_names
        data.pressure = data.prDM
    elseif "prSM" in data_names
        data.pressure = data.prSM
    elseif "depSM" in data_names
        data.pressure = pressure_from_depth.(data.depSM)
    else
        error("No 'pr', 'prdM', 'prDM', 'prSM' or 'depSM' in CNV file; found ", names(data))
    end
    if "c0mS/cm" in data_names # FIXME: allow S/m etc; convert here to store mS/cm for gsw
        data.conductivity = data[:, "c0mS/cm"]
    elseif "c1mS/cm" in data_names
        data.conductivity = data[:, "c1mS/cm"]
    end
    if "t068" in data_names
        data.temperature = T90_from_T68.(data.t068)
    elseif "t090" in data_names
        data.temperature = data.t090
    elseif "t090C" in data_names
        data.temperature = data.t090C
    elseif "t190C" in data_names
        data.temperature = data.t190C
    elseif "tv290C" in data_names
        data.temperature = data.tv290C
    elseif "tv268C" in data_names
        data.temperature = data.tv268C
    else
        error("No 't068', 't090', 't090C', 't190C', 't290C', 'tv268C' in CNV file; found ", names(data))
    end
    if "sal00" in data_names
        data.salinity = data.sal00
    else
        if "conductivity" in names(data)
            data.salinity = salinity_from_conductivity.(data.conductivity, data.temperature, data.pressure)
        else
            error("No 'sal00' column in CNV file and no conductivity either; found ", names(data))
        end
    end
    #data.SA = gsw_sa_from_sp.(data.salinity, data.pressure, metadata["longitude"], metadata["latitude"])
    #data.CT = gsw_ct_from_t.(data.SA, data.temperature, data.pressure)
    #data.sigma0 = gsw_sigma0.(data.SA, data.CT)
    #data.spiciness0 = gsw_spiciness0.(data.SA, data.CT)
    #oad(debug, "    combining .metadata and .data into a Ctd object")
    #println("metadata lat=", metadata["latitude"])
    #println("metadata lon=", metadata["longitude"])
    #rval = Ctd(metadata, data)
    # Add any nonstandard columns that are in the file. Below is how this
    # is done (successfully) by read_argo().
    #    rval = as_ctd(salinity, temperature, pressure, longitude, latitude,
    #                  time=time, debug=debug > 0 ? debug + 1 : 0)
    oad(debug, "    calling as_ctd() to create a Ctd object, as the skeleton of the return value")
    if isnan(latitude) || isnan(longitude)
        rval = as_ctd(data.salinity, data.temperature, data.pressure,
            NaN, NaN, time=time, debug=debug > 0 ? debug + 1 : 0)
    else
        rval = as_ctd(data.salinity, data.temperature, data.pressure,
            longitude, latitude, time=time, debug=debug > 0 ? debug + 1 : 0)
    end
    oad(debug, "    adding non-standard variables to the '.data' component of return value")
    #println("data...")
    #println(first(data, 2)) # FIXME
    #println("rval.data...")
    #println(first(rval.data, 2)) # FIXME
    standard_items = ["salinity", "temperature", "pressure", "conductivity"]
    for name in names(data)
        if !(name in standard_items)
            oad(debug, "        adding '", name, "'")
            rval.data[:, name] = data[:, name]
        end
    end
    # Add nonstandard metadata that are in the file
    oad(debug, "        adding header and filename to the '.metadata' component of return value")
    rval.metadata["header"] = header
    rval.metadata["filename"] = filename
    oad(debug, "END read_ctd_cnv()")
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
    local SA = gsw_sa_from_sp.(o.salinity, o.pressure, o.longitude, o.latitude) |> fix_gsw_bad_code!
    if name == "SA"
        return copy(SA)
    end
    local CT = gsw_ct_from_t.(SA, o.temperature, o.pressure) |> fix_gsw_bad_code!
    if name == "CT"
        return copy(CT)
    end
    if name == "sigma0"
        return copy(gsw_sigma0.(SA, CT)) |> fix_gsw_bad_code!

    elseif name == "spiciness0"
        return copy(gsw_spiciness0.(SA, CT)) |> fix_gsw_bad_code!

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
    oad(debug, "END N2()")
    return N2
end


end # module OceanAnalysis
