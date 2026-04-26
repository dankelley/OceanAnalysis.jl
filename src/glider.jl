using NCDatasets, OceanAnalysis, GibbsSeaWater, Plots, Dates, Printf, DataFrames


const ARGO_DICT = Dict("doxy" => "oxygen",
    "pres" => "pressure", "psal" => "salinity", "temp" => "temperature");

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
    rename!(data, ARGO_DICT)
    Glider(metadata, data)
end

# metadata, data = read_glider("sp028_20230202T1637_R.nc");
# println(metadata)
# println(names(data))
# 
# const PLOT_DEFAULTS = (color=:blue, legend=false, markersize=1.4, tickfontsize=6, guidefontsize=6, titlefontsize=6, framestyle=:box, tickdirection=:out);
# 
# p1 = scatter(data.time, data.pressure, yflip=true, ylab="Pressure [dbar]"; PLOT_DEFAULTS...);
# p2 = scatter(data.time, data.salinity, ylab="Salinity"; PLOT_DEFAULTS...);
# p3 = scatter(data.time, data.temperature, ylab="Temperature [°C]"; PLOT_DEFAULTS...);
# p4 = scatter(data.time, data.profile_index, ylab="Profile Index"; PLOT_DEFAULTS...);
# plot(p1, p2, p3, p4, layout=(4, 1))
# savefig("05a.pdf")
# p5 = scatter(data.salinity, data.pressure, yflip=true, xlab="Salinity", ylab="Pressure [dbar]"; PLOT_DEFAULTS...);
# p6 = scatter(data.temperature, data.pressure, yflip=true, xlab="Temperature [°C]", ylab="Pressure [dbar]"; PLOT_DEFAULTS...);
# p7 = scatter(data.salinity, data.temperature, xlab="Salinity", ylab="Temperature [°C]"; PLOT_DEFAULTS...);
# plot(p5, p6, p7, layout=(1, 3))
# savefig("05b.pdf")
# 
