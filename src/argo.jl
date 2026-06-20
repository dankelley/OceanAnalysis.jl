const atm = Dict(
    1 => "Platform Identification test (ID=2)",
    2 => "Impossible Date test (ID=4)",
    3 => "Impossible Location test (ID=8)",
    4 => "Position on Land test (ID=16)",
    5 => "Impossible Speed test (ID=32)",
    6 => "Global Range test (ID=64)",
    7 => "Regional Global Parameter test (ID=128)",
    8 => "Pressure Increasing test (ID=256)",
    9 => "Spike test (ID=512)",
    10 => "Top and Bottom spike test (ID=1024) DEPRECATED",
    11 => "Gradient test (ID=2048) DEPRECATED",
    12 => "Digit Rollover test (ID=4096)",
    13 => "Stuck Value test (ID=8192)",
    14 => "Density Inversion test (ID=16384)",
    15 => "Supplemental sensor exclusion list test (ID=32768)",
    16 => "Gross Salinity or Temperature Sensor Drift test (ID=65536)",
    17 => "Visual QC test (ID=131072)",
    18 => "Frozen profile test (ID=262144) ERRONEOUSLY PRINTED 261144 IN ARGO MANUALS",
    19 => "Deepest pressure test (ID=524288)",
    20 => "Questionable Argos position test (ID=1048576)",
    21 => "Near-surface unpumped CTD salinity test (ID=2097152)",
    22 => "Near-surface mixed air/water test (ID=4194304)",
    23 => "Interim rtqc flag scheme for data deeper than 2000 dbar (ID=8388608)",
    24 => "Interim rtqc flag scheme for data from experimental sensors (ID=16777216)",
    25 => "MEDD test (ID=33554432)",
    26 => "TEMP_CNDC test applied to RBRargo32K (ID=67108864)")

"""
    argo_test_meaning(i)

Return label for Argo data test (if `i` is from 2 to 27) or list of possible labels (if `i<2).

The meanings are from https://vocab.nerc.ac.uk/collection/R11/current/, consulted 2026-05-04.
"""
function argo_test_meaning(i::Integer)
    if i < 1
        keys = sort(collect(keys(atm)))
        return [atm[key] for key in keys]
    elseif haskey(atm, i)
        return atm[i]
    else
        error("Test index $i not found")
    end
end

"""
    character_vector_to_string(x)::String

Convert vector of characters into a string.
"""
function character_vector_to_string(x)::String
    # New version is non-mutating
    #OLD x[ismissing.(x)] .= ' '
    #OLD replace(join(x), " " => "")
    rval = String[]
    for xx in x
        if ismissing(xx)
            continue
        end
        push!(rval, replace(string(xx), " " => ""))
    end
    return strip(join(rval))
end

"""
    summarize_argo_data_tests(filename::String)

Summarize tests performed on an Argo dataset. This is used by `summarize()` for
[`Argo`](@ref) objects, and it may also be called directly.  The test names are
taken from https://vocab.nerc.ac.uk/collection/R11/current/ (accessed on
2026-05-04). Two things should be noted about the tests.

1. Some of the test descriptions have varied across versions of Argo
   documentation. For example, test 15, with ID 32768, was called "Grey List
   test" in Carval et al. (2019 page 84, reference table 11), but it was called
   "Supplemental sensor exclusion list test" in Wong et al. (2025 page 109,
   reference table 11).
2. The two sources just listed describe test 18 as having ID 261144, although
   it ought to be 262144, since the scheme otherwise uses powers of 2.

**References**

Carval, Thierry, Bob Keeley, Yasushi Takatsuki, et al. _Argo User’s Manual V3.3_. Ifremer, 2019. [https://doi.org/10.13155/29825](https://doi.org/10.13155/29825).

Wong, Annie, Robert Keeley, Thierry Carval, and Argo Data Management Team. _Argo Quality Control Manual for CTD and Trajectory Data. Version 3.9. Ifremer, 2025. [https://doi.org/10.13155/33951](https://doi.org/10.13155/33951).

"""
function summarize_argo_data_tests(filename::String)
    NCDataset(filename, "r") do d
        ha = d["HISTORY_ACTION"] # 16 x nprofiles x ntests
        hq = d["HISTORY_QCTEST"] # 16 x nprofiles x ntests
        dim = size(ha)
        for j in 1:dim[2]
            println("  Profile $j")
            for k in 1:dim[3]
                test = character_vector_to_string(ha[:, j, k])
                result = character_vector_to_string(hq[:, j, k])
                if test == "QCP\$"
                    result_bits = collect(string(parse(Int, result, base=16), base=2))
                    println("    Tests performed (based on HISTORY_ACTION value 0x$result, interpreted as $(join(result_bits))):")
                    i = 1
                    for bit in result_bits[end-1:-1:1]
                        if bit == '1'
                            println("      test $i: $(argo_test_meaning(i))")
                        end
                        i = i + 1
                    end
                elseif test == "QCF\$"
                    result_bits = collect(string(parse(Int, result, base=16), base=2))
                    println("    Tests failed (based on HISTORY_QCTEST value 0x$result, intepreted as $(join(result_bits))):")
                    i = 1
                    some_failed = false
                    for bit in result_bits[end-1:-1:1]
                        if bit == '1'
                            println("      test $(i): $(argo_test_meaning(i))")
                            some_failed = true
                        end
                        i = i + 1
                    end
                    if !some_failed
                        println("      no tests failed")
                    end
                end
            end
        end
    end
end


"""
    argo_id_cycle(idcycle::String="")

Split Argo "id_cycle" into components `id` and `cycle`.

# Examples
```jldoctest
using OceanAnalysis
argo_id_cycle("4902911_095")

# output
2-element Vector{SubString{String}}:
 "4902911"
 "095"
```
"""
function argo_id_cycle(idcycle::String="")
    !isempty(idcycle) || throw(ArgumentError("'idcycle' must be a non-empty string"))
    occursin(r"_", idcycle) || throw(ArgumentError("'idcycle' must contain an underline character"))
    split(idcycle, "_")
end


"""
    read_argo(filename::String; profile::Integer=1, debug::Integer=0)::Argo

Read a profile within an Argo file. For convenience, such files may be
downloaded with [`get_argo`](@ref).

# Arguments

- `filename` a String holding the name of a NetCDF file that holds Argo data.

# Keywords

- `profile` an integer, indicating which profile to read from the file.

- `debug` indicator of debugging level. If this exceeds 0, some information is printed during processing.

# Return value

The `read_argo()` function returns an [`Argo`](@ref) object that has two
components: (1) a Dict named `.metadata` that has entries named `"cycle"`,
`"data_mode"`, `"date_creation"`, `"filename"`, `"latitude"`, `"longitude"`,
`"platform"`, and `"time"`, perhaps along with other entries. (2) A DataFrame
named `data` that has elements stored in the data file.

# Examples
```julia
using OceanAnalysis
pkgdir = dirname(dirname(pathof(OceanAnalysis)));
f = joinpath(pkgdir, "data", "D4902911_095.nc");
d = read_argo(f);
d.metadata["time"] # 2019-10-14T23:43:44.003
d.metadata["latitude"] # 40.45216
d.metadata["longitude"] # -66.38298
size(d.data) # (1014, 15)
```
"""
function read_argo(filename::String; profile::Integer=1, debug::Integer=0)::Argo
    oad(debug, "read_argo(<filename>; profile=$profile, debug=$debug) START")
    metadata = Dict()
    data = DataFrame()
    oad(debug, "  filename: $filename")
    NCDataset(filename, "r") do d
        metadata = Dict()
        # Find names of the data columns (see https://github.com/dankelley/OceanAnalysis.jl/issues/60)
        data_names_original = [v for v in keys(d) if "N_LEVELS" in dimnames(d[v])]
        data_names = rename_data(data_names_original)
        # Insist that salinity, temperature and pressure are found.
        3 == sum(in.(data_names, (Set(["salinity", "temperature", "pressure"]),))) ||
            error("Cannot find salinity, temperature or pressure in $(filename)")
        name_changes = Dict(data_names .=> data_names_original)
        for key in keys(name_changes)
            if endswith(key, "qc")
                data[!, key] = d[name_changes[key]][:, profile]
            else
                tmp1 = d[name_changes[key]][:, profile]
                data[!, key] = map(x -> ismissing(x) ? NaN : Float64(x), tmp1)
            end
        end
        oad(debug, "  finished reading data, a DataFrame of size $(size(data))")
        metadata["name_changes"] = name_changes
        metadata["longitude"] = get_nc_value(d, "LONGITUDE")
        metadata["latitude"] = get_nc_value(d, "LATITUDE")
        metadata["time"] = d["JULD"][1] # NCDatasets converts this to a Date.DateTime for us!
        # Do some things directly, because get_nc_value() is designed for numeric items
        if haskey(d, "DATE_CREATION")
            metadata["date_creation"] = DateTime(join(d["DATE_CREATION"]), dateformat"yyyymmddHHMMSS")
        else
            metadata["date_creation"] = missing
        end
        # Some files don't have a DATA_MODE entry, so we set it to blank in that case
        if haskey(d, "DATA_MODE")
            metadata["data_mode"] = d["DATA_MODE"][1]
        else
            metadata["data_mode"] = "?"
        end
        metadata["filename"] = filename
        # Remove trailing blanks in platform ID code, to avoid user problems with e.g. aggregating cycles
        metadata["platform"] = replace(join(d["PLATFORM_NUMBER"][:, 1]), "missing" => "")
        # I think one cycle can hold many profiles, so we only examine the first CYCLE_NUMBER value
        metadata["cycle"] = d["CYCLE_NUMBER"][1]
        oad(debug, "  finished reading metadata, a Dict holding $(length(metadata)) items")
    end
    oad(debug, "END read_argo()")
    return Argo(metadata, data)
end # read_argo()


"""
    get_argo_index(destdir::String="."; age::Real=1.0,
        server::String="https://data-argo.ifremer.fr", debug::Integer=0)

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
function get_argo_index(destdir::String="."; age::Real=1.0, server::String="https://data-argo.ifremer.fr", debug::Integer=0)
    oad(debug, "get_argo_index() START")
    file = "ar_index_global_prof.txt.gz"
    local_file = joinpath(destdir, file)
    oad(debug, "  local_file: \"$local_file\"")
    remote_file = chomp(server, '/') * "/" * file
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

# Return value

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
function get_argo(filename::String=""; destdir::String=".", age::Real=30.0, server::String="https://data-argo.ifremer.fr", debug::Integer=0)
    oad(debug, "get_argo() START")
    file_original = filename
    oad(debug, "    filename: ", filename, " (original)")
    filename = replace(filename, r".*/" => "")
    file = joinpath(destdir, filename)
    oad(debug, "    filename: ", filename, " (after prefixing with destdir)")
    url = joinpath(server, "dac", file_original)
    oad(debug, "    url: ", url)
    rval = get_file(url; destdir=destdir, age=age, debug=increment_debug(debug))
    oad(debug, "END get_argo()")
    rval
end


"""
    read_argo_index(filename::String; trim::Bool=true, header::Integer=9, debug::Integer=0)

Read an Argo file, as downloaded by [`get_argo_index`](@ref).

This relies on there being exactly `header` lines of header, the last of which
names the columns.  The default value of 9 works with index files downloaded
from the ifremer.fr server, as of 2025-09-08.

First, the `date` column is converted to a DateTime column named `time`.  If
`trim` is true, then the original `date` column is removed, along with the the
columns named `institution`, `date_update`, `ocean`, and `profiler_type`.

# Return value

`read_argo_index` returns a DataFrame with column names `"file"`, `"latitude"`,
`"longitude"`, and `"time"`. Note that the `"file"` column holds information on
the location on remote servers, as is required for use as the `file` argument
of [`get_argo`](@ref).

"""
function read_argo_index(filename::String; trim::Bool=true, header::Integer=9, debug::Integer=0)::DataFrame
    file = expanduser(filename)
    oad(debug, "read_argo_index() START")
    if !isfile(file)
        error("No file file named '$file'")
    end
    oad(debug, "    filename: ", filename)
    df = CSV.read(filename, DataFrame, header=header)
    norig = nrow(df)
    dropmissing!(df)
    nnew = nrow(df)
    oad(debug, "    dropped ", norig - nnew, " rows (", round(100 * (norig - nnew) / norig, digits=3), "% of total) because of missing data")
    # create 'time', then remove 'date'
    ok_to_trim_date = true
    try
        df.time = DateTime.(string.(df.date), dateformat"yyyymmddHHMMSS")
    catch
        println("ERROR computing df.time from df.date, so leaving the latter for user to deal with")
        ok_to_trim_date = false
    end
    if trim
        if ok_to_trim_date
            oad(debug, "    trimming 'date' column (use 'time' instead)")
            select!(df, Not(:date))
        end
        # Remove the some things that may not be needed in all applications.
        #columns_to_drop = [:institution, :date_update, :ocean, :profiler_type]
        columns_to_drop = [:ocean]
        select!(df, Not(columns_to_drop))
    end
    oad(debug, "END read_argo_index()")
    return df
end

