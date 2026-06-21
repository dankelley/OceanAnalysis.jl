"""
    read_ctd_cnv(filename::String; rename::Bool=true, add_teos::Bool=true, debug::Integer=0)::Ctd

Read a Seabird CTD file in cnv format, optionally adding TEOS-10 variables.

Returns a [`Ctd`](@ref) object that holds `metadata` and `data`. The `metadata`
item is a Dict that holds `header` (a vector of strings, one per line from the
start down to a line containing `#END`), plus some particular items scanned
from that header, e.g. `"longitude"` and `"latitude"`. The `data` item is a
DataFrame holding the columnar data read from the file. If `rename=true`, then
[`rename_data`](@ref) is used to rename some of the columns in `data` to better
match oceanographic conventions (e.g. `"pr"` becomes `"pressure"`). If the data
file indicates temperature is on the T68 scale, then this is converted to the
standard modern scale, T90, before saving as `temperature`. 

A message is printed if no data in the file are labelled with names that are
recognized as salinity, temperature, or pressure, because these quantities are
required for any meaningful CTD dataset.

The value of `add_teos` is passed to [`as_ctd`](@ref), where it indicates
whether to add TEOS-10 variables such as `SA`, `CT`, `sigma0` and `spiciness0`
to the `data` portion of the return value.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");

julia> d = read_ctd_cnv(f, add_teos=false);

julia> d.metadata["time"] # note the erroneous year
1903-10-15T11:38:38

julia> d.metadata["latitude"]
1-element Vector{Float64}:
 44.684266666666666

julia> d.metadata["longitude"]
1-element Vector{Float64}:
 -63.643883333333335

julia> names(d.data)
8-element Vector{String}:
 "salinity"
 "temperature"
 "pressure"
 "scan"
 "time_seconds"
 "depS"
 "t068"
 "flag"
```
"""
function read_ctd_cnv(filename::String; rename::Bool=true, add_teos::Bool=true, debug::Integer=0)::Ctd
    #!ismissing(filename) || error("please supply 'filename'")
    filename = expanduser(filename)
    open(filename) do file
        read_ctd_cnv(file, filename; rename=rename, add_teos=add_teos, debug=increment_debug(debug))
    end
end

# Internal function used byRead a Seabird CTD file in cnv format, optionally adding TEOS-10 variables.
function read_ctd_cnv(stream::IOStream, filename::String=""; rename::Bool=true, add_teos::Bool=true, debug::Integer=0)
    oad(debug, "read_ctd_cnv(\"", filename, "\", ...) START")
    lines = readlines(stream)
    #oad(debug, "  $(length(lines)) lines in file")
    data_names = Vector{String}()
    oad(debug, "  assembling metadata (a Dict)")
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
                oad(debug, "  NOTE: the names of data columns start at line ", i)
            end
            tokens = split(line)
            name = replace(tokens[5], ":" => "")
            push!(data_names, name)
        elseif occursin(r"^# start_time", line)
            # Do this step by step, to make it easier to find problems if we
            # encounter files in formats that are not currently handled.
            time_string = split(line, " = ")[2]
            oad(debug, "  time_string '", time_string, "'")
            time_string = replace(time_string, r" \[.*$" => "")
            #oad(debug, "time_string '", time_string, "'")
            time_string = strip(time_string)
            #oad(debug, "time_string '", time_string, "'")
            time = DateTime(time_string, time_format)
            oad(debug, "  inferred time=", time)
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
            oad(debug, "  inferred latitude=", latitude)
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
            oad(debug, "  inferred latitude=", latitude)
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
            oad(debug, "  inferred longitude=", longitude)
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
            oad(debug, "  NOTE: the data columns start at line ", data_start)
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
    oad(debug, "  reading nrows=$(nrows), ncols=$(ncols)")
    data = Array{Float64,2}(undef, nrows, ncols)
    irow = 1
    for i in data_start:length(lines)
        d = parse.(Float64, split(lines[i]))
        data[irow, :] = d
        irow = irow + 1
    end
    metadata["header"] = header
    oad(debug, "  assembling data (a DataFrame)")
    data = DataFrame(data, data_names, makeunique=true)
    data_names = names(data)
    data_names_orig = data_names
    if rename
        data_names_new = rename_data(data_names)
        changed = data_names_new .!== data_names
        if sum(changed) > 0
            data_names = data_names_new
            oad(debug, "  renamed $(sum(changed)) data columns, as follows")
            oad(debug, "  $(data_names_orig .=> data_names)")
        else
            oad(debug, "  no columns were renamed")
        end
    end
    # FIXME: rename also prdM prDM prSM depSM
    # if "pr" in data_names
    #     data.pressure = data.pr
    # elseif "prdM" in data_names
    #     data.pressure = data.prdM
    # elseif "prDM" in data_names
    #     data.pressure = data.prDM
    # elseif "prSM" in data_names
    #     data.pressure = data.prSM
    # elseif "depSM" in data_names
    #     data.pressure = pressure_from_depth.(data.depSM)
    # else
    #     error("No 'pr', 'prdM', 'prDM', 'prSM' or 'depSM' in CNV file; found ", names(data))
    # end
    #if "c0mS/cm" in data_names # FIXME: allow S/m etc; convert here to store mS/cm for gsw
    #    data.conductivity = data[:, "c0mS/cm"]
    #elseif "c1mS/cm" in data_names
    #    data.conductivity = data[:, "c1mS/cm"]
    #end
    if "t068" in data_names
        data.temperature = T90_from_T68.(data.t068)
        oad(debug, "  converted T068 temperature (e.g. $(first(data.t068, 2))) to T90 (e.g. $(first(data.temperature, 2)))")
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
    #println(first(data, 3))
    rename!(data, data_names_orig .=> data_names)
    #println(first(data, 3))
    if !("salinity" in data_names) && (("conductivity" in data_names) && ("temperature" in data_names) && ("pressure" in data_names))
        data.salinity = salinity_from_conductivity.(data.conductivity, data.temperature, data.pressure)
    end
    #if "sal00" in data_names
    #    data.salinity = data.sal00
    #else
    #    if "conductivity" in names(data)
    #        data.salinity = salinity_from_conductivity.(data.conductivity, data.temperature, data.pressure)
    #    else
    #        error("No 'sal00' column in CNV file and no conductivity either; found ", names(data))
    #    end
    #end
    oad(debug, "  calling as_ctd() to create a Ctd object, as the skeleton of the return value")
    if isnan(latitude) || isnan(longitude)
        rval = as_ctd(data.salinity, data.temperature, data.pressure,
            time=time, add_teos=add_teos, debug=increment_debug(debug))
    else
        rval = as_ctd(data.salinity, data.temperature, data.pressure, longitude=longitude, latitude=latitude,
            time=time, add_teos=add_teos, debug=increment_debug(debug))
    end
    standard_items = ["salinity", "temperature", "pressure", "conductivity"]
    for name in names(data)
        if !(name in standard_items)
            oad(debug, "  adding non-standard column named ", name, " to data")
            rval.data[:, name] = data[:, name]
        end
    end
    # Add nonstandard metadata that are in the file
    oad(debug, "  adding header and filename to metadata")
    rval.metadata["header"] = header
    rval.metadata["filename"] = filename
    oad(debug, "END read_ctd_cnv()")
    rval
end

