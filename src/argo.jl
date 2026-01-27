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
    read_argo(filename::String; column::Int64=1, add_teos::Bool=true, debug::Int64=0)

Read an Argo file and return a [`Ctd`](@ref) object that holds salinity,
temperature, pressure (and derived columns) but no other columns from the file.
This function is in an early stage of development; please report problems as
    issues on <www.github.com/dankelley/OceanAnalysis.jl/issues>.

The value of `add_teos` is passed to [`as_ctd`](@ref), where it indicates
whether to add TEOS-10 variables such as `SA`, `CT`, `sigma0` and `spiciness0`
to the `data` portion of the return value.

Set `debug` to a positive integer to cause `read_argo()` to print messages
during processing. This can be handy if problems arise.

# Return value

The `read_argo()` function returns a [`Ctd`](@ref) object that has two
components, a Dict named `.metadata` and DataFrame named `.data`. The
`.metadata` entries are named `"cycle"`, `"data_mode"`, `"date_creation"`,
`"filename"`, `"latitude"`, `"longitude"`, `"platform"`, and `"time"`. The
`.data` columns are named `"pressure"`, `"salinity"` and `"temperature"`,
as copied from fields in the NetCDF file named `"PRES"`, `"PSAL"`
and `"TEMP"`; no other NetCDF fields are copied in this version
of `read_argo()`.

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

julia> first(d.data,3)
3×7 DataFrame
 Row │ salinity  temperature  pressure  SA       CT       sigma0   spiciness0
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────
   1 │   34.913       19.513      0.48  35.0786  19.5079  24.8272     3.31464
   2 │   34.91        19.527      1.0   35.0756  19.5219  24.8213     3.31603
   3 │   34.912       19.524      2.0   35.0776  19.5187  24.8237     3.31669
```
"""
function read_argo(filename::String; column::Int64=1, add_teos::Bool=true, debug::Int64=0)
    if ismissing(filename)
        error("must give 'filename'")
    end
    oad(debug, "read_argo(<filename>; column=$column, debug=$debug) START")
    local rval = nothing
    NCDataset(filename, "r") do d
        # Find names of the data columns (see https://github.com/dankelley/OceanAnalysis.jl/issues/60)
        data_names_original = [v for v in keys(d) if "N_LEVELS" in dimnames(d[v])]
        oad(debug, "    column names in file: $(data_names_original)")
        data_names = rename_data(data_names_original)
        oad(debug, "    after renaming, have data_names: $(data_names)")
        # Insist that salinity, temperature and pressure are found.
        found = sum(in.(data_names, (Set(["salinity", "temperature", "pressure"]),)))
        if found != 3
            if debug == 0
                error("Cannot find salinity, temperature or pressure in $(filename); try rerunning with debug=1 to learn more")
            else
                error("Cannot find salinity, temperature or pressure in $(filename)")
            end
        end
        name_list = Dict(data_names .=> data_names_original)
        data = DataFrame()
        for key in keys(name_list)
            if contains(key, r"_qc$")
                data[!, key] = parse.(Int, Char.(get_nc_value(d, name_list[key])))
            else
                data[!, key] = convert(Vector{Union{Missing,Float64}}, get_nc_value(d, name_list[key]))
            end
        end
        longitude = get_nc_value(d, "LONGITUDE")
        if ismissing(longitude)
            println("read_argo() found missing longitude")
        end
        oad(debug, "    read longitude: $longitude")
        latitude = get_nc_value(d, "LATITUDE")
        if ismissing(latitude)
            println("read_argo() found missing latitude")
        end
        oad(debug, "    read latitude: $latitude")
        time = d["JULD"][1] # NCDatasets converts this to a Date.DateTime for us!
        oad(debug, "    read time: $time")
        rval = as_ctd(data.salinity, data.temperature, data.pressure, longitude=longitude, latitude=latitude,
            time=time, add_teos=add_teos, debug=increment_debug(debug))
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
    file = replace.(file, r".*/" => "")
    oad(debug, "    filename: ", filename, " (after trimming)")
    file = joinpath(destdir, filename)
    oad(debug, "    filename: ", filename, " (after prefixing with destdir)")
    url = joinpath(server, "dac", file_original)
    oad(debug, "    url: ", url)
    rval = get_file(url, filename, age, debug=increment_debug(debug))
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

