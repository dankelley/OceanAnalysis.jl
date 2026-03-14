"""
    Split Argo "id_cycle" into components id and cycle

# Examples
```jldoctest
julia> using OceanAnalysis

julia> argo_id_cycle("4902911_095")
2-element Vector{SubString{String}}:
 "4902911"
 "095"
```
"""
function argo_id_cycle(idcycle::String="")
    if 0 == length(idcycle) || !occursin(r"_", idcycle)
        error("'idcycle', a string containing an underline character, must be supplied")
    else
        split(idcycle, "_")
    end
end


"""
    read_argo(filename::String; column::Int64=1, debug::Int64=0)

    Read an Argo file.

# Arguments

- `filename` a String holding the name of a NetCDF file that holds Argo data.

# Keywords

- `column` an integer, indicating which profile to read from the file.

- `debug` indicator of debugging level. If this exceeds 0, some information is printed during processing.

# Return value

The `read_argo()` function returns an [`Argo`](@ref) object that has two
components, a Dict named `.metadata` and DataFrame named `.data`. The
`.metadata` entries are named `"cycle"`, `"data_mode"`, `"date_creation"`,
`"filename"`, `"latitude"`, `"longitude"`, `"platform"`, and `"time"`. The
`.data` columns are taken from the source file.

# Examples
```jldoctest
julia> using OceanAnalysis, Plots

julia> pkgdir = dirname(dirname(pathof(OceanAnalysis)));

julia> f = joinpath(pkgdir, "data", "D4902911_095.nc");

julia> d = read_argo(f);

julia> d.metadata["time"]
2019-10-14T23:43:44.003

julia> d.metadata["latitude"]
40.45216

julia> d.metadata["longitude"]
-66.38298

julia> size(d.data)
(1014, 15)
```
"""
function read_argo(filename::String; column::Int64=1, add_teos::Bool=true, debug::Int64=0)
    oad(debug, "read_argo(<filename>; column=$column, debug=$debug) START")
    metadata = Dict()
    data = DataFrame()
    oad(debug, "  filename: $filename")
    NCDataset(filename, "r") do d
        metadata = Dict()
        # Find names of the data columns (see https://github.com/dankelley/OceanAnalysis.jl/issues/60)
        data_names_original = [v for v in keys(d) if "N_LEVELS" in dimnames(d[v])]
        data_names = rename_data(data_names_original)
        # Insist that salinity, temperature and pressure are found.
        found = sum(in.(data_names, (Set(["salinity", "temperature", "pressure"]),)))
        if found != 3
            if debug == 0
                error("Cannot find salinity, temperature or pressure in $(filename); try rerunning with debug=1 to learn more")
            else
                error("Cannot find salinity, temperature or pressure in $(filename)")
            end
        end
        name_changes = Dict(data_names .=> data_names_original)
        for key in keys(name_changes)
            if contains(key, r"_qc$")
                #oad(debug, "  QC item $key")
                #println(d[name_changes[key]])
                #tmp1 = d[name_changes[key]][:, column]
                #n = length(tmp1)
                #tmp2 = repeat([0], n)
                #ok = .!ismissing.(tmp1)
                #tmp2[ok] .= parse.(Int, Char.(tmp1[ok]))
                #TMP2 = map(x -> ismissing(x) ? NaN : Int64(x), tmp1)
                data[!, key] = d[name_changes[key]][:, column]
                #data[!, key] = tmp2
                #oad(debug, "  QC item $key has $(sum(ismissing(TMP2))) missing data out of $(length(TMP2)) data")
            else
                #oad(debug, "  non-QC item $key")
                tmp1 = d[name_changes[key]][:, column]
                #tmp2 = convert(Vector{Union{Missing,Float64}}, tmp1)
                #tmp2[ismissing.(tmp2)] .= NaN
                TMP2 = map(x -> ismissing(x) ? NaN : Float64(x), tmp1)
                #n = length(tmp1)
                #tmp2 = repeat([0.0], n)
                #bad = ismissing.(tmp1)
                #tmp2[bad] .= NaN
                #println("DAN tmp1 starts $(first(tmp1,6))")
                #println("DAN tmp1 ends$(last(tmp1,6))")
                #println("DAN tmp1 # missing: ", sum(ismissing.(tmp1)))
                #println("DAN tmp1 has ", sum(ismissing.(tmp1)), " missing data out of ", length(tmp1), " data")
                #tmp = convert(Vector{Union{Missing,Float64}}, get_nc_value(d, name_changes[key]))
                #tmp2[!bad] .= tmp1[.!bad]
                #oad(debug, "  steppingstone")
                data[!, key] = TMP2
                #data[!, key] = tmp2
                #oad(debug, "  non-QC item $key has $(sum(ismissing(TMP2))) missing data out of $(length(TMP2)) data")
            end
        end
        oad(debug, "  finished reading data, a DataFrame of size $(size(data))")
        metadata["name_changes"] = name_changes
        metadata["longitude"] = get_nc_value(d, "LONGITUDE")
        #if ismissing(metadata["longitude"])
        #    println("read_argo() found missing longitude")
        #end
        #oad(debug, "    read longitude: $longitude")
        metadata["latitude"] = get_nc_value(d, "LATITUDE")
        #if ismissing(latitude)
        #    println("read_argo() found missing latitude")
        #end
        #oad(debug, "    read latitude: $latitude")
        metadata["time"] = d["JULD"][1] # NCDatasets converts this to a Date.DateTime for us!
        #oad(debug, "    read time: $time")
        #rval.data = data
        #rval = as_ctd(data.salinity, data.temperature, data.pressure, longitude=longitude, latitude=latitude,
        #    time=time, add_teos=add_teos, debug=increment_debug(debug))
        #oad(debug, "    extending ctd object .metadata by adding argo-specific items")
        # Do some things directly, because get_nc_value() is designed for numeric items
        if haskey(d, "DATE_CREATION")
            metadata["date_creation"] = DateTime(join(d["DATE_CREATION"]), dateformat"yyyymmddHHMMSS")
        else
            metadata["date_creation"] = missing
        end
        # Some files don't have a DATA_MODE entry, so we set it to blank in that case
        #print(sort(keys(d)))
        if haskey(d, "DATA_MODE")
            #print("ok? ", d["DATA_MODE"][1])
            metadata["data_mode"] = d["DATA_MODE"][1]
        else
            metadata["data_mode"] = "?"
        end
        metadata["filename"] = filename
        # Remove trailing blanks in platform ID code, to avoid user problems with e.g. aggregating cycles
        metadata["platform"] = replace(join(d["PLATFORM_NUMBER"][:, 1]), "missing" => "")
        # I think one cycle can hold may profiles, so we only examine the first CYCLE_NUMBER value
        metadata["cycle"] = d["CYCLE_NUMBER"][1]
        oad(debug, "  finished reading metadata, a Dict holding $(length(metadata)) items")
    end
    oad(debug, "END read_argo()")
    Argo(metadata, data)
end # read_argo()


"""
    get_argo_index(destdir::String="."; age::Real=1.0,
        server::String="https://data-argo.ifremer.fr", debug::Int64=0)

Download an Argo index file, unless an existing local copy is newly downloaded.

The file is obtained from `server` and stored in `destdir`, but only if an
existing version of the file in `destdir` is under `age` days old. The default
is to cache index files for one day.

The default `destdir` is the local directory, but it is common to set this
value to some central location so the file can be used by Julia sessions
running in multiple directories. (The author sets `destdir="~/data/argo"`, for
example.)

# Return value

`read_argo_index` returns the full name of the downloaded (or cached)
file.

Use [`read_argo_index`](@ref) to interpret the downloaded file.
"""
function get_argo_index(destdir::String="."; age::Real=1.0, server::String="https://data-argo.ifremer.fr", debug::Int64=0)
    oad(debug, "get_argo_index() START")
    file = "ar_index_global_prof.txt.gz"
    local_file = joinpath(destdir, file)
    oad(debug, "  local_file: \"$local_file\"")
    remote_file = joinpath(server, file)
    oad(debug, "  remote_file: \"$remote_file\"")
    oad(debug, "  age: \"$age\"")
    rval = get_file(remote_file; destdir, age, debug=increment_debug(debug))
    oad(debug, "END get_argo_index()")
    rval
end

"""
    get_argo(filename::String="", destdir::String="."; age::Real=1.0; server::String="https://data-argo.ifremer.fr", debug=0)

Download an Argo profile file, if an existing copy is less than `age` days old.

# Arguments

- `file`: path to the file on a server, of the form `agency/#/profiles/-#_##.nc`, where `#` is the ID number of the float, `-` tells the status of the file (`R` for realtime files, `D` for delayed-mode files, etc.) and `##` is an identifier for the cast (usually but not always an integer value). This system matches the `file` information stored on argo servers, as downloaded by [`get_argo_index`](@ref) and read by [`read_argo_index`](@ref).

# Keywords

- `destdir`: name of the directory into which to save the file.

- `age`: file-caching time in days.  If the requested file does not exist locally then `age` is ignored and the file is downloaded.  It will also be downloaded if there is an existing file but it was last downloaded more than `age` days ago.

- `server`: base URL for the server (it is very unlikely that users will set this

- `debug`: integer indicating whether to print information during processing. The default
value of 0 means to work silently.

# Returns

- `get_argo` returns the full path name of the local file after downloading, or as cached recently.

# Example

```julia
# Get most last-named file in the Argo index and plot a temperature profile
using OceanAnalysis
index_file = get_argo_index()
index = read_argo_index(index_file)
argo_file = get_argo(index.file[end])
argo = read_argo(argo_file)
plot_profile(argo, which="CT")
```

"""
function get_argo(filename::String=""; destdir::String=".", age::Real=30.0, server::String="https://data-argo.ifremer.fr", debug::Int64=0)
    oad(debug, "get_argo() START")
    file_original = filename
    oad(debug, "    filename: ", filename, " (original)")
    file = replace.(filename, r".*/" => "")
    file = joinpath(destdir, filename)
    oad(debug, "    filename: ", filename, " (after prefixing with destdir)")
    url = joinpath(server, "dac", file_original)
    oad(debug, "    url: ", url)
    rval = get_file(url; destdir=destdir, age=age, debug=increment_debug(debug))
    oad(debug, "END get_argo()")
    rval
end


"""
    read_argo_index(filename::String; trim::Bool=true, header::Int64=9, debug::Int64=0)

Read a file downloaded by [`get_argo_index`](@ref).

This relies on there being exactly `header` lines of header, the last of which
names the columns.  The default value of 9 works with index files downloaded
from the ifremer.fr server, as of 2025-09-08.

First, the `date` column is converted to a DateTime column named `time`.  If
`trim` is true, then the original `date` column is removed, along with the the
columns named `institution`, `date_update`, `ocean`, and `profiler_type`.

# Return

`read_argo_index` returns a DataFrame with column names `"file"`, `"latitude"`,
`"longitude"`, and `"time"`. Note that the `"file"` column holds information on
the location on remote servers, as is required for use as the `file` argument
    of [`get_argo`](@ref).
"""
function read_argo_index(filename::String; trim::Bool=true, header::Int64=9, debug::Int64=0)
    file = expanduser(filename)
    oad(debug, "read_argo_index() START")
    if !isfile(file)
        error("No file file named ", filename)
    end
    oad(debug, "    filename: ", filename)
    df = CSV.read(filename, DataFrame, header=header)
    norig = nrow(df)
    dropmissing!(df)
    nnew = nrow(df)
    oad(debug, "    dropped ", norig - nnew, " rows (", round(100 * (norig - nnew) / norig, digits=3), "% of total) because of missing data")
    #<REMOVED 2025-09-09> df.file = replace.(df.file, r".*/" => "")
    # create 'time', then remove 'date'
    ok_to_trim_date = true
    try
        df.time = DateTime.(string.(df.date), dateformat"yyyymmddHHMMSS")
    catch e
        println("ERROR computing df.time from df.date, so leaving the latter for user to deal with")
        ok_to_trim_date = false
    end
    if trim
        if ok_to_trim_date
            oad(debug, "    trimming 'date' column (use 'time' instead)")
            select!(df, Not(:date))
        end
        # Remove the some things that may not be needed in all applications.
        oad(debug, "    trimming 'institution' column")
        select!(df, Not(:institution))
        oad(debug, "    trimming 'date_update' column")
        select!(df, Not(:date_update))
        oad(debug, "    trimming 'ocean' column")
        select!(df, Not(:ocean))
        oad(debug, "    trimming 'profiler_type' column")
        select!(df, Not(:profiler_type))
    end
    oad(debug, "END read_argo_index()")
    return df
end

