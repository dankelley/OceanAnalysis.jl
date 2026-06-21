"""
    read_ctd_exchange(filename::String; add_teos=true, debug::Integer=0)

Read a CTD file in 'exchange' format

Returns a [`Ctd`](@ref) object that holds `metadata` (a Dict) and `data` (a
DataFrame). The `metadata` item is a Dict holding `header` (the information at
the start of the file, down to a line starting `DBAR,`), along with various
quantities, renamed to lower case and some computed quantities, e.g. datetime
is constructed from `DATE` and `TIME` in the file. The `data` item is a
DataFrame holding the data.  The names are altered to be easier to guess, e.g.
`CTDPRS` becomes `pressure`. Since `metadata["header"]` holds the original
header, users ought to be able to deal with any confusion about names without
too much difficulty.

The value of `add_teos` is passed to [`as_ctd`](@ref), where it indicates
whether to add TEOS-10 variables such as `SA`, `CT`, `sigma0` and `spiciness0`
to the `data` portion of the return value.

NOTE: The 'exchange' format is commonly supplied by data repositories such as
[https://cchdo.ucsd.edu](https://cchdo.ucsd.edu), with web links that are typically accompanied with a
description containing the word "exchange". The present function *cannot*
handle a related file format, called 'WOCE', but this limitation should not
be too problematic because servers tend to supply both formats. (The function
reports an error if it is provided with a file in 'WOCE' format.)

# Examples

```julia
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ar07_74JC20140606_00234_00001_ct1.csv");
d = read_ctd_exchange(f);
println(keys(d.metadata))
#["latitude", "time", "header", "section", "longitude", "bottom_depth", "station", "expocode", "cast"]

println(first(d.data, 3))
# 3×8 DataFrame
#  Row │ pressure  pressure_flag  temperature  temperature_flag  salinity  salinity_flag  oxygen   oxygen_flag
#      │ Float64   Int64          Float64      Int64             Float64   Int64          Float64  Int64
# ─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────
#    1 │      5.0              2      13.1134                 2   34.1855              2    266.0            2
#    2 │      7.0              2      13.1195                 2   34.1844              2    266.8            2
#    3 │      9.0              2      13.1152                 2   34.1837              2    266.4            2
```
"""
function read_ctd_exchange(filename::String; add_teos=true, debug::Integer=0)
    !ismissing(filename) || error("please supply 'filename'")
    filename = expanduser(filename)
    open(filename) do file
        read_ctd_exchange(file, filename; add_teos=add_teos, debug=debug)
    end
end

# Internal function used to read an exchange CTD file, optionally adding TEOS-10 variables.
function read_ctd_exchange(stream::IOStream, filename::String=""; add_teos=true, debug::Integer=0)
    oad(debug, "read_ctd_exchange(\"", filename, "\", ...) START")
    lines = readlines(stream)
    # ensure the file is in the right format FIXME: maybe just warn?
    if !occursin(r"^CTD,[0-9a-zA-Z]+$", lines[1])
        if occursin(r"^EXPOCODE", lines[1])
            error("This is an 'exchange' file, which is not handled. Try working with \"woce\" files instead.")
        else
            error("This is not a 'woce' file, since it does not start with \"CTD,\" followed by letters and numbers")
        end
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
    metadata["bottom_depth"] = parse(Float64, metadata["DEPTH"])
    delete!(metadata, "DEPTH")
    metadata["section_id"] = metadata["SECT_ID"]
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
    rows, cols = size(data)
    oad(debug, "  read $rows of data, each with $cols columns")
    rval = Ctd(metadata, data)
    oad(debug, "END read_ctd_exchange()")
    rval
end

