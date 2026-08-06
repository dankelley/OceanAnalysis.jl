# FIXME: add more to this list, as we see them in files

"""
    glider_dictionary

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
glider_dictionary
```
"""


const glider_dictionary = Dict(
    # Sample file(s):
    #   1. https://upwell.pfeg.noaa.gov/erddap/files/scrippsGliders/batch17/sp007-20200827T110800.nc
    # Data
    "doxy" => "oxygen",
    "flu2" => "fluorescence",
    "head" => "heading",
    "lon" => "longitude",
    "lat" => "latitude",
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
export glider_dictionary

"""
    read_glider(file::String; skip_qc::Bool=true, debug::Integer=0)

Read glider data from a NetCDF file named `file`. This code is very
preliminary, tested on only a few sample files. Essentially, it reads all
vector-form variables in the file, possibly ignoring ones with names ending in
`_qc`, and then stores the data for those variables in columns in `data`. Some
variables things are renamed, e.g. `"psal"` becomes `"salinity"`. Note that all
the names in `data` are in lower case, no matter whether they are lower or
upper case in the NetCDF file, and that variable names are transformed
according to [`glider_dictionary`](@ref).
"""
function read_glider(file::String; skip_qc::Bool=false, debug::Integer=0)
    oad(debug, "read_glider() START")
    oad(debug, "  file: $file")
    oad(debug, "  skip_qc: $skip_qc")

    metadata = Dict()
    metadata["file"] = file
    metadata["skip_qc"] = skip_qc
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
    oad(debug, "  columns before renaming: $(names(data))")
    for (old, new) in glider_dictionary
        oad(debug, "  renaming \"$old\" as \"$new\"")
        rename!(n -> replace(n, Regex("^" * old * "\$") => new), data)
    end
    oad(debug, "  columns after renaming: $(names(data))")
    rval = Glider(metadata, data)
    oad(debug, "END read_glider()")
    rval
end
export read_glider

