using NCDatasets, OceanAnalysis, GibbsSeaWater, Plots, Dates, Printf, DataFrames


const ARGO_DICT = Dict(:doxy => :oxygen,
    :profile_index => :profile, :profile_number => :profile,
    :pres => :pressure, :psal => :salinity, :temp => :temperature);

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
function read_glider(file::String; skip_qc::Bool=true, debug::Integer=0)
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
    Glider(metadata, data)
end

