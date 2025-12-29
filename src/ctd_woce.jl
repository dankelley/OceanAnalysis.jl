"""
    read_ctd_woce(filename::String; add_teos=true, debug::Int64=0)

Read a WOCE exchange CTD file

Returns a [`Ctd`](@ref) object that holds `metadata` (a Dict) and `data` (a
DataFrame). The `metadata` item is a Dict holding `header` (the information
at the start of the file, down to a line starting `DBAR,`),
along with various quantities, renamed to lower case and 
some computed quantities, e.g. datetime is constructed from
`DATE` and `TIME` in the file. The `data` item is a DataFrame
holding the data.  The names are altered to be easier to
guess, e.g. `CTDPRS` becomes `pressure`. Since `metadata["header"]`
holds the original header, users ought to be able to deal
with any confusion about names without too much difficulty.

The value of `add_teos` is passed to [`as_ctd`](@ref), where it indicates
whether to add TEOS-10 variables such as `SA`, `CT`, `sigma0` and `spiciness0`
to the `data` portion of the return value.

# Examples

```juliadoctest
julia> f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ar07_74JC20140606_00234_00001_ct1.csv");

julia> d = read_ctd_woce(f);

julia> println(keys(d.metadata))
["depth", "latitude", "time", "header", "section", "longitude", "station", "expocode", "cast"]

julia> println(first(d.data, 3))
3×8 DataFrame
 Row │ pressure  pressure_flag  temperature  temperature_flag  salinity  salinity_flag  oxygen   oxygen_flag
     │ Float64   Int64          Float64      Int64             Float64   Int64          Float64  Int64
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │      5.0              2      13.1134                 2   34.1855              2    266.0            2
   2 │      7.0              2      13.1195                 2   34.1844              2    266.8            2
   3 │      9.0              2      13.1152                 2   34.1837              2    266.4            2
```
```
"""
function read_ctd_woce(filename::String; add_teos=true, debug::Int64=0)
    !ismissing(filename) || error("please supply 'filename'")
    filename = expanduser(filename)
    open(filename) do file
        read_ctd_woce(file, filename; add_teos=add_teos, debug=debug)
    end
end

# Internal function used to read a WOCE CTD file, optionally adding TEOS-10 variables.
function read_ctd_woce(stream::IOStream, filename::String=""; add_teos=true, debug::Int64=0)
    oad(debug, "read_ctd_woce(\"", filename, "\", ...) START")
    lines = readlines(stream)
    # ensure the file is in the right format FIXME: maybe just warn?
    if !occursin(r"^CTD,[0-9a-zA-Z]+$", lines[1])
        error("This file does not start with 'CTD,' followed by letters and numbers")
    end
    # find header length
    header_length = 0
    for i in eachindex(lines)
        if occursin(r"^NUMBER_HEADERS", lines[i])
            leftover = parse(Int64, split(lines[i], r"[ ]*=[ ]*")[2])
            header_length = i + leftover + 1
            break
        end
    end
    metadata = Dict()
    header = lines[1:header_length]
    metadata["header"] = header
    for i in eachindex(header)
        if occursin(r"=", header[i])
            key, value = split(header[i], r"[ ]*=[ ]*")
            if key == "SECT"
                key = "SECT_ID"
            end
            metadata[key] = value
        end
    end
    # Change from strings to numeric, and also rename
    metadata["longitude"] = parse(Float64, metadata["LONGITUDE"])
    delete!(metadata, "LONGITUDE")
    metadata["latitude"] = parse(Float64, metadata["LATITUDE"])
    delete!(metadata, "LATITUDE")
    metadata["depth"] = parse(Float64, metadata["DEPTH"])
    delete!(metadata, "DEPTH")
    metadata["section"] = metadata["SECT_ID"]
    delete!(metadata, "SECT_ID")
    metadata["station"] = metadata["STNNBR"]
    delete!(metadata, "STNNBR")
    metadata["cast"] = metadata["CASTNO"]
    delete!(metadata, "CASTNO")
    metadata["expocode"] = metadata["EXPOCODE"]
    delete!(metadata, "EXPOCODE")
    # FIXME DATE AND TIME
    time_string = metadata["DATE"] * metadata["TIME"]
    time = DateTime(time_string, "yyyymmddHHMM")
    metadata["time"] = time
    delete!(metadata, "DATE")
    delete!(metadata, "TIME")
    # Clean up useless item
    delete!(metadata, "NUMBER_HEADERS")
    #println("second-last header line: " * lines[header_length-1])
    #println("last header line: " * lines[header_length])
    # Get data
    # CTDPRS,CTDPRS_FLAG_W,CTDTMP,CTDTMP_FLAG_W,CTDSAL,CTDSAL_FLAG_W,CTDOXY,CTDOXY_FLAG_W
    data_names = String.(split(lines[header_length-1], ","))
    #println("orig data_names: ")
    #println(data_names)
    data_names = replace.(data_names, "CTDPRS" => "pressure", "CTDTMP" => "temperature", "CTDSAL" => "salinity", "CTDOXY" => "oxygen",
        "_FLAG_W" => "_flag")
    #println("new data_names: ")
    #println(data_names)
    seekstart(stream)
    data = CSV.read(stream, DataFrame; delim=",", header=false, skipto=header_length + 1, footerskip=1, silencewarnings=true)
    rename!(data, data_names)
    Ctd(metadata, data)
end

#     #oad(debug, "    $(length(lines)) lines in file")
#     data_names = Vector{String}()
#     oad(debug, "    assembling metadata (a Dict)")
#     metadata = Dict{String,Any}()
#     time_format = DateFormat("u d yyy HH:MM:SS")
#     # set defaults
#     header = ""
#     data_start = 0
#     time = nothing
#     latitude = NaN
#     longitude = NaN
#     names_found = false
#     data_start = 0
#     latitude = NaN # to catch case where file lacks this info
#     longitude = NaN # to catch case where file lacks this info
#     for i in eachindex(lines)
#         line = lines[i]
#         #oad(debug, "examining line: '", line, "'")
#         if occursin(r"^# name ", line)
#             if !names_found
#                 names_found = true
#                 oad(debug, "    NOTE: the names of data columns start at line ", i)
#             end
#             tokens = split(line)
#             name = replace(tokens[5], ":" => "")
#             push!(data_names, name)
#         elseif occursin(r"^# start_time", line)
#             # Do this step by step, to make it easier to find problems if we
#             # encounter files in formats that are not currently handled.
#             time_string = split(line, " = ")[2]
#             oad(debug, "    time_string '", time_string, "'")
#             time_string = replace(time_string, r" \[.*$" => "")
#             #oad(debug, "time_string '", time_string, "'")
#             time_string = strip(time_string)
#             #oad(debug, "time_string '", time_string, "'")
#             time = DateTime(time_string, time_format)
#             oad(debug, "    inferred time=", time)
#         elseif occursin(r"^\*.* [Ll]atitude:", line) # e.g. "** Latitude: 74 15.88 N"
#             #println("try to decode latitude in ** : format")
#             #println("1. line=", line)
#             sign = occursin(r"[Ss]", line) ? -1 : 1
#             #println("2. sign=", sign)
#             line = replace(line, r"[NSns]" => "") |> strip
#             #println("3. after remove hemisphere line='", line, "'")
#             s = split(line, ": ")[2] |> strip
#             s = replace(s, r"\*" => "") # some files have a * (for degree sign, I suppose)
#             #println("4. s=", s)
#             ss = split(s, r"[ ]+")
#             #println("5. ss= ", ss)
#             latitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
#             oad(debug, "    inferred latitude=", latitude)
#         elseif occursin(r"^\*.* [Ll]atitude[ ]*=", line) # e.g. "* NMEA Latitude = 70 33.09 N"
#             #println("lat= case")
#             #println(line)
#             s = split(line, "=")[2]
#             #println("s after split: '", s, "'")
#             sign = occursin(r"[sS]", s) ? -1 : 1
#             #println("sign=", sign)
#             s = replace(s, r"[NSns]" => "") |> strip
#             #println("Before split for deg and dec-min, s='", s, "'")
#             ss = split(s, r"[ ]+")
#             #println("after split, ss=", ss)
#             latitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
#             oad(debug, "    inferred latitude=", latitude)
#         elseif occursin(r"^\*.* [Ll]ongitude:", line)
#             #println("1. line=", line)
#             sign = occursin(r"[Ww]", line) ? -1 : 1
#             #println("2. sign=", sign)
#             line = replace(line, r"[EWew]" => "") |> strip
#             #println("3. after remove hemisphere = ", line)
#             s = split(line, ": ")[2] |> strip
#             s = replace(s, r"\*" => "") # some files have a * (for degree sign, I suppose)
#             #println("4. s=", s)
#             ss = split(s, r"[ ]+")
#             #println("5. ss= ", ss)
#             longitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
#             oad(debug, "    inferred longitude=", longitude)
#         elseif occursin(r"^\*.* [Ll]ongitude[ ]*=", line) # e.g. "* NMEA Longitude = 132 40.03 W"
#             #println(line)
#             s = split(line, " = ")[2]
#             #println(s)
#             sign = occursin(r"[Ww]", s) ? -1 : 1
#             #println(sign)
#             replace(s, r"[eEwW]" => "")
#             #println(s)
#             ss = split(s, r"[ ]+")
#             longitude = sign * (parse(Float64, ss[1]) + parse(Float64, ss[2]) / 60.0)
#         elseif occursin(r"^\*\*.*:", line)
#             #println("line with colon: '$line'")
#             tokens = split(line, ":")
#             item = lowercase(replace(tokens[1], "** " => ""))
#             value = replace(tokens[2], r"^ *" => "")
#             metadata[item] = value
#         elseif occursin(r"\*END\*", line)
#             data_start = i + 1
#             oad(debug, "    NOTE: the data columns start at line ", data_start)
#             header = lines[1:i]
#             break
#         end
#     end
#     if data_start == 0
#         error("This file has no *END* line, so columns cannot be identified")
#     end
#     if length(data_names) == 0
#         error("No '# name' lines in header, so columns cannot be identifed")
#     end
#     ncols = length(split(lines[data_start]))
#     if ncols != length(data_names)
#         error("ncols=$ncols does not match length(data_names)=$(length(data_names))")
#     end
#     nrows = length(lines) - data_start + 1
#     oad(debug, "    datanames: $data_names")
#     oad(debug, "    reading nrows=$(nrows), ncols=$(ncols)")
#     data = Array{Float64,2}(undef, nrows, ncols)
#     irow = 1
#     for i in data_start:length(lines)
#         d = parse.(Float64, split(lines[i]))
#         data[irow, :] = d
#         irow = irow + 1
#     end
#     metadata["header"] = header
#     oad(debug, "    assembling data (a DataFrame)")
#     data = DataFrame(data, data_names, makeunique=true)
#     data_names = names(data)
#     oad(debug, "    data names: ", data_names)
#     # Add standard columns
#     if "pr" in data_names
#         data.pressure = data.pr
#     elseif "prdM" in data_names
#         data.pressure = data.prdM
#     elseif "prDM" in data_names
#         data.pressure = data.prDM
#     elseif "prSM" in data_names
#         data.pressure = data.prSM
#     elseif "depSM" in data_names
#         data.pressure = pressure_from_depth.(data.depSM)
#     else
#         error("No 'pr', 'prdM', 'prDM', 'prSM' or 'depSM' in CNV file; found ", names(data))
#     end
#     if "c0mS/cm" in data_names # FIXME: allow S/m etc; convert here to store mS/cm for gsw
#         data.conductivity = data[:, "c0mS/cm"]
#     elseif "c1mS/cm" in data_names
#         data.conductivity = data[:, "c1mS/cm"]
#     end
#     if "t068" in data_names
#         data.temperature = T90_from_T68.(data.t068)
#     elseif "t090" in data_names
#         data.temperature = data.t090
#     elseif "t090C" in data_names
#         data.temperature = data.t090C
#     elseif "t190C" in data_names
#         data.temperature = data.t190C
#     elseif "tv290C" in data_names
#         data.temperature = data.tv290C
#     elseif "tv268C" in data_names
#         data.temperature = data.tv268C
#     else
#         error("No 't068', 't090', 't090C', 't190C', 't290C', 'tv268C' in CNV file; found ", names(data))
#     end
#     if "sal00" in data_names
#         data.salinity = data.sal00
#     else
#         if "conductivity" in names(data)
#             data.salinity = salinity_from_conductivity.(data.conductivity, data.temperature, data.pressure)
#         else
#             error("No 'sal00' column in CNV file and no conductivity either; found ", names(data))
#         end
#     end
#     oad(debug, "    calling as_ctd() to create a Ctd object, as the skeleton of the return value")
#     if isnan(latitude) || isnan(longitude)
#         rval = as_ctd(data.salinity, data.temperature, data.pressure,
#             time=time, add_teos=add_teos, debug=increment_debug(debug))
#     else
#         rval = as_ctd(data.salinity, data.temperature, data.pressure, longitude=longitude, latitude=latitude,
#             time=time, add_teos=add_teos, debug=increment_debug(debug))
#     end
#     standard_items = ["salinity", "temperature", "pressure", "conductivity"]
#     for name in names(data)
#         if !(name in standard_items)
#             oad(debug, "    adding non-standard column named ", name, " to data")
#             rval.data[:, name] = data[:, name]
#         end
#     end
#     # Add nonstandard metadata that are in the file
#     oad(debug, "    adding header and filename to metadata")
#     rval.metadata["header"] = header
#     rval.metadata["filename"] = filename
#     oad(debug, "END read_ctd_cnv()")
#     rval
# end

