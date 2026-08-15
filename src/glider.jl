# FIXME: add more to this list, as we see them in files

using GibbsSeaWater: gsw_sigma0

"""
    GLIDER_DICTIONARY

A `Dict` used by [`read_glider()`](@ref) to transform variable names in Argo
files. For example, the string `"pres"` will be transformed `"pressure"`, the
string `"quality_control"` will be transformed to `"qc"`. The result is that
the `data` component of a glider object read by [`read_glider()`](@ref) will
tend to have uniform (and conventional) names. Not all items are renamed,
so users are asked to contact the developer if they have files with names
not handled here.

# Examples
```julia
using OceanAnalysis
GLIDER_DICTIONARY
```
"""
const GLIDER_DICTIONARY = Dict(
    # Sample file(s):
    #   1. https://upwell.pfeg.noaa.gov/erddap/files/scrippsGliders/batch17/sp007-20200827T110800.nc
    #   2. sbloom2023.nc
    # Data
    "absolute_salinity" => "SA",
    "conservative_temperature" => "CT",
    "doxy" => "oxygen",
    "flu2" => "fluorescence",
    "head" => "heading",
    "lat" => "latitude",
    "lon" => "longitude",
    "oxygen_concentration" => "oxygen",
    "pres" => "pressure",
    "profile_index" => "profile",
    "profile_number" => "profile",
    "psal" => "salinity",
    "quality_control" => "qc",
    "temp" => "temperature",
    # QC flags
    "c_qc" => "conductivity_qc",
    "d_qc" => "depth_qc", # I see this in file 1, even though it has no 'depth' data
    "lat_qc" => "latitude_qc",
    "lon_qc" => "longitude_qc",
    "p_qc" => "pressure_qc",
    "s_qc" => "salinity_qc",
    "t_qc" => "temperature_qc",
);
export GLIDER_DICTIONARY

"""
    read_glider(file::String; interpolate_locations::Bool=true, skip_qc::Bool=false, debug::Integer=0)

Read glider data from a NetCDF file named `file`, storing all vector-form
variables in the file in the results (although possibly ignoring ones with
names ending in `_qc`, if instructed). Many variables are renamed according to
[`GLIDER_DICTIONARY`](@ref). If both `SA` and `CT` are present, but
`sigma0` is not present, then the later is computed and stored in the
result. By default, longitude and latitude are across missing values.

This function was written in summer 2026, and has been used on only a few
sample files to date. Its performance is adequate, e.g. taking 3 seconds to
read a 139M file. Users should expect some changes to column names and
possibly other things, through the autumn of 2026.

# Arguments

- `file` a String naming a NetCDF file holding glider data.

# Keywords

- `interpolate_locations` a Bool that indicates whether to interpolate
  longitude and latitude linearly with respect to time. This is useful in files
  that have non-missing locations only at swoops when data were transmitted. If
  the file already has fully non-missing location data, this is ignored. If the
  file has no non-missing location data, a warning is issued. If there is just a
  single non-missing location, it is copied through all the rows of the
  resultant.  And, finally (the usual case) if the file has more than 1
  non-missing location, then both longitude and latitude are interpolated
  linearly.

- `skip_qc` Bool value indicating whether to skip reading QC (quality-control)
  values. This is false by default.

# Return value

An [`Glider`](@ref) object with `metadata` holding some information about
the glider, and with `data` holding a DataFrame with the measured and
inferred data.
"""
function read_glider(file::String; interpolate_locations::Bool=true, skip_qc::Bool=false, debug::Integer=0)
    oad(debug, "read_glider() START")
    oad(debug, "  file: $file")
    oad(debug, "  interpolate_locations: $interpolate_locations")
    oad(debug, "  skip_qc: $skip_qc")
    metadata = Dict()
    metadata["file"] = file
    metadata["skip_qc"] = skip_qc
    metadata["interpolate_locations"] = interpolate_locations
    data = DataFrame()
    NCDataset(expanduser(file), "r") do d
        oad(debug, "  opened file '$file'")
        # Get a list of all dimension names
        # Print all dimension names and their sizes
        if debug > 0
            for (name, len) in d.dim
                println("  dimension $name has length $len")
            end
        end
        if !("time" in keys(d.dim))
            error("cannot read a glider file unless it has a \"time\" dimension")
        end
        ntime = d.dim["time"]
        # metadata
        for item in ("title", "institution", "platform_code", "references")
            metadata[item] = haskey(d.attrib, item) ? d.attrib[item] : ""
            oad(debug, "  defined metadata[\"$(item)\"]")
        end
        # data
        qc_regexp = r"_qc$"
        oad(debug, "  size(data): $(size(data))")
        for key in keys(d)
            oad(debug, "  key: \"$key\"")
            var = d[key]
            if length(var) == ntime
                if 1 == ndims(var)
                    if !skip_qc || !occursin(qc_regexp, key)
                        data[!, lowercase(key)] = copy(var)
                    end
                else
                    oad(debug, "  skipping key \"$(key)\" because it has more than 1 dimension")
                end
            else
                oad(debug, "  skipping key \"$(key)\" because its length ($(length(var))) does not equal that of \"time\" ($ntime))")
            end
        end
    end
    # Rename columns
    oad(debug, "  columns before renaming: $(sort(names(data)))")
    debug == 0 || println(GLIDER_DICTIONARY)
    for (old, new) in GLIDER_DICTIONARY
        oad(debug, "  renaming \"$old\" as \"$new\"")
        rename!(n -> replace(n, Regex("^" * old * "\$") => new), data)
    end
    oad(debug, "  columns after renaming: $(sort(names(data)))")
    if !("sigma0" in names(data)) && ("SA" in names(data)) && ("CT" in names(data))
        oad(debug, "  adding sigma0, since we have SA and CT")
        n = size(data, 1)
        sigma0 = Array{Union{Missing,Float64}}(missing, n)
        ok = .!ismissing.(data.SA) .&& .!ismissing.(data.CT)
        sigma0[ok] = gsw_sigma0.(data.SA[ok], data.CT[ok])
        data.sigma0 = sigma0
    end
    if interpolate_locations
        if "longitude" in names(data) && "latitude" in names(data) && "time" in names(data)
            ok = .!ismissing.(data.latitude) .&& .!ismissing.(data.longitude)
            nok = sum(ok)
            oad(debug, "  nok: ", nok)
            if nok == 0
                @warn "no good locations, so cannot interpolate over missing values"
            else
                if nok == nrow(data)
                    oad(debug, "  not interpolating locations, since file has no bad values")
                elseif nok == 1
                    nrows = nrow(data)
                    oad(debug, "  using the non-missing value for all latitude and longitude")
                    i = findfirst(!ismissing, data.latitude)
                    data.latitude = repeat([data.latitude[i]], nrows)
                    i = findfirst(!ismissing, data.longitude)
                    data.longitude = repeat([data.longitude[i]], nrows)
                else
                    oad(debug, "  interpolating longitude and latitude by time")
                    lonlat = interpolate_to_time(DataFrame(time=data.time, lon=data.longitude, lat=data.latitude))
                    data.longitude = lonlat.lon
                    data.latitude = lonlat.lat
                end
            end
        end
    end
    rval = Glider(metadata, data)
    oad(debug, "END read_glider()")
    rval
end
export read_glider

