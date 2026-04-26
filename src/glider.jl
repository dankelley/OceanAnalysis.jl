#using NCDatasets, OceanAnalysis, GibbsSeaWater, Plots, Dates, Printf, DataFrames

# FIXME: add more to this list, as we see them in files
const ARGO_DICT = Dict(
    :cdom_quality_control => :cdom_qc,
    :depth_quality_control => :depth_qc,
    :density_quality_control => :density_qc,
    :doxy => :oxygen,
    :doxy_qc => :oxygen_qc,
    :doxy_quality_control => :oxygen_qc,
    :flu2 => :fluorescence,
    :flu2_qc => :fluorescence_qc,
    :flu2_quality_control => :fluorescence_qc,
    :pres => :pressure,
    :pres_qc => :pressure_qc,
    :pres_quality_control => :pressure_qc,
    :profile_index => :profile,
    :profile_number => :profile,
    :psal => :salinity,
    :psal_qc => :salinity_qc,
    :psal_quality_control => :salinity_qc,
    :temp => :temperature,
    :temp_qc => :temperature_qc,
    :temp_quality_control => :temperature_qc,
);

"""
    read_glider(file::String; skip_qc::Bool=true, debug::Integer=0)

Read glider data from a NetCDF file named `file`. This code is very
preliminary, tested on only a few sample files. Essentially, it
reads all vector-form variables in the file, possibly ignoring ones
with names ending in `_qc`, and then stores the data for those
variables in columns in `data`. Some variables things are renamed,
e.g. `"psal"` becomes `"salinity"`. Note that all the names in
`data` are in lower case, no matter whether they are lower or
upper case in the NetCDF file.
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
    for (old, new) in ARGO_DICT
        if hasproperty(data, old)
            rename!(data, old => new)
        end
    end
    rval = Glider(metadata, data)
    oad(debug, "END read_glider()")
    rval
end

