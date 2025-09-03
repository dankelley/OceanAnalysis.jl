"""
    as_ctd(salinity, temperature, pressure, longitude=NaN, latitude=NaN; time, debug=-1)

Construct a [`Ctd`](@ref) object, given S, T, p, and a location.

Returns a [`Ctd`](@ref) object with a `data` element that is a data frame
holding the provided water properties, along with computed Absolute Salinity
(`SA`) Conservative Temperature (`CT`), potential density anomaly relative to
the surface pressure (`sigma0`) and spiciness with respect to surface pressure
(`spiciness0`).  The object also holds a `metadata` element that holds
`longitude`, `latitude` and `time`.  If either `longitude` or `latitude` is
NaN, then`SA`, etc. are computed assuming a mid-Atlantic location (-30E and
30N).

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
Ctd(Dict{String, Any}("latitude" => 40.0, "time" => nothing, "longitude" => -63.0), 1×3 DataFrame
 Row │ salinity  temperature  pressure
     │ Float64   Float64      Float64
─────┼─────────────────────────────────
   1 │     32.0         15.0       0.0)
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
    # DELETE  Removed 2025-09-03 because it's only for plot_*() and those functions can
    # DELETE  easily compute SA and CT if desired.
    # DELETE     if ismissing(longitude) || ismissing(latitude) || isnan(longitude) || isnan(latitude)
    # DELETE         lon = -30.0
    # DELETE         lat = 30.0
    # DELETE         println("as_ctd() given NaN longitude/latitude values, so SA, CT, etc. computed at -30E, 30N.")
    # DELETE     else
    # DELETE         lon = longitude
    # DELETE         lat = latitude
    # DELETE     end
    # DELETE     local SA = gsw_sa_from_sp.(salinity, pressure, lon, lat) |> fix_gsw_bad_code!
    # DELETE     oad(debug, "    created SA of length ", length(SA), ", which starts: ", first(SA, 2))
    # DELETE     local CT = gsw_ct_from_t.(SA, temperature, pressure) |> fix_gsw_bad_code!
    # DELETE     oad(debug, "    created CT of length ", length(CT), ", which starts: ", first(CT, 2))
    # DELETE     sigma0 = gsw_sigma0.(SA, CT) |> fix_gsw_bad_code!
    # DELETE     oad(debug, "    created sigma0 of length ", length(sigma0), ", which starts: ", first(sigma0, 2))
    # DELETE     spiciness0 = gsw_spiciness0.(SA, CT) |> fix_gsw_bad_code!
    # DELETE     oad(debug, "    created spiciness0 of length ", length(spiciness0), ", which starts: ", first(spiciness0, 2))
    # DELETE end
    oad(debug, "    assembling data (a DataFrame) from the above")
    # DELETE   data = DataFrame(salinity=salinity, temperature=temperature,
    # DELETE       pressure=pressure, SA=SA, CT=CT, sigma0=sigma0, spiciness0=spiciness0)
    data = DataFrame(salinity=salinity, temperature=temperature, pressure=pressure)
    oad(debug, "    assembling metadata (a Dict)")
    metadata = Dict{String,Any}()
    # DELETE     Note that we are inserting the longitude and latitude from the function call,
    # DELETE     not the -30,30 values that we invented in order to estimate SA, CT, sigma0 and spicines0
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

A message is printed if no data in the file are labelled with names that are
recognized as salinity, temperature, or pressure, because these quantities are
required for any meaningful CTD dataset.  Also, if longitude and latitude
cannot can be inferred from the file, a message is printed to indicate that
mid-Atlantic values (-30E and 30N) are assumed, so that Absolute Salinity,
`SA`, and other TEOS-10 quantities can be approximated, as these
are needed for other functions in the package.

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
    oad(debug, "    assembling metadata (a Dict)")
    metadata = Dict{String,Any}()
    time_format = DateFormat("u d yyy HH:MM:SS")
    # set defaults
    header = ""
    data_start = 0
    time = nothing
    latitude = NaN
    longitude = NaN
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
    oad(debug, "    assembling data (a DataFrame)")
    data = DataFrame(data, data_names, makeunique=true)
    data_names = names(data)
    oad(debug, "    data names: ", data_names)
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

