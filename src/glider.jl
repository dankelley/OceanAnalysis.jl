# FIXME: add more to this list, as we see them in files

"""
    glider_dictionary

A `Dict` used by [`read_glider()`](@ref) to transform variable names in Argo
files. For example, the string `"pres"` will be transformed `"pressure"`, the
string `"quality_control"` will be transformed to `"qc"`. The result is that
the `data` component of a glider object read by [`read_glider()`](@ref) will
tend to have uniform names, freeing the user from having to know that a given
file uses upper- or lower-case names, whether quality-control entities have
suffix `"quality_control"` or `"qc"`, and so forth.
"""
const glider_dictionary = Dict(
    "quality_control" => "qc",
    "doxy" => "oxygen",
    "flu2" => "fluorescence",
    "head" => "heading",
    "pres" => "pressure",
    "profile_index" => "profile",
    "profile_number" => "profile",
    "psal" => "salinity",
    "temp" => "temperature",
);

"""
    read_glider(file::String; skip_qc::Bool=true, debug::Integer=0)

Read glider data from a NetCDF file named `file`. This code is very
preliminary, tested on only a few sample files. Essentially, it reads all
vector-form variables in the file, possibly ignoring ones with names ending in
`_qc`, and then stores the data for those variables in columns in `data`. Some
variables things are renamed, e.g. `"psal"` becomes `"salinity"`. Note that all
the names in `data` are in lower case, no matter whether they are lower or
upper case in the NetCDF file, and that variable names are transformed
according to the a Dict named `glider_dictionary` in the src/glider.jl source
file.
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
        # metadata
        for item in ("title", "institution", "platform_code", "references")
            metadata[item] = haskey(d.attrib, item) ? d.attrib[item] : ""
        end
        # data
        qc_regexp = r"_qc$"
        for key in keys(d)
            var = d[key]
            if 1 == ndims(var)
                if !skip_qc || !occursin(qc_regexp, key)
                    data[!, lowercase(key)] = copy(var)
                    oad(debug, " Stored column $key")
                else
                    oad(debug, " Skipped QC column $key")
                end
            end
        end
    end
    # Rename columns
    for (old, new) in glider_dictionary
        rename!(n -> replace(n, Regex(old) => new), data)
    end
    rval = Glider(metadata, data)
    oad(debug, "END read_glider()")
    rval
end

