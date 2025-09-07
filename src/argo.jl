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
    read_argo(filename, column=1; add_teos=true, require_valid=true, debug=0)

Read an Argo file and return a Ctd object that holds salinity, temperature,
pressure (and derived columns) but no other columns from the file.  As of
2025-08-23, this code is still in rapid development; please report problems as
issues on <www.github.com/dankelley/OceanAnalysis.jl/issues>.

The value of `add_teos` is passed to [`as_ctd`](@ref), where it indicates
whether to add TEOS-10 variables such as `SA`, `CT`, `sigma0` and `spiciness0`
to the `data` portion of the return value.

If `require_valid` is true (the default) then an error is reported if the file
lacks one of three required data columns, or either longitude or latitude.  An
error is also reported if any of these items consists entirely of missing
values. This is because such files are unlikely to be of much use. In some
cases, setting `require_valid` to false may permit the file to be read, but
this has not been tested, since the results in such cases are not likely to be
of practical use.

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

julia> d = read_argo(f, 1);

julia> d.metadata["time"]
2019-10-14T23:43:44.003

julia> d.metadata["latitude"]
40.45216

julia> d.metadata["longitude"]
-66.38298

julia> names(d.data)
7-element Vector{String}:
 "salinity"
 "temperature"
 "pressure"
 "SA"
 "CT"
 "sigma0"
 "spiciness0"
```
"""
function read_argo(filename, column=1; add_teos=true, require_valid=true, debug::Int64=0)
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
            println("read_argo() found missing longitude")
        end
        oad(debug, "    read longitude: $longitude")
        latitude = get_nc_value(d, "LATITUDE", require_valid)
        if ismissing(latitude)
            println("read_argo() found missing latitude")
        end
        oad(debug, "    read latitude: $latitude")
        # Non-numeric items cannot be retrieved with get_nc_value(), so we get
        # them directly.
        time = d["JULD"][1] # NCDatasets converts this to a Date.DateTime for us!
        oad(debug, "    read time: $time")
        rval = as_ctd(salinity, temperature, pressure, longitude, latitude,
            time=time, add_teos=add_teos, debug=debug > 0 ? debug + 1 : 0)
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
