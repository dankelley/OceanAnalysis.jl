# This has been incorporated into src/ctd_rsk.jl

using SQLite, DataFrames, Plots, Dates, Printf, Statistics
using OceanAnalysis, GibbsSeaWater
function oad(debug::Int64=0, msg="")
    if debug > 0
        println(msg)
    end
end

function read_ctd_rsk_trial(filename::String; debug::Int64=0)
    f = expanduser(filename)
    db = SQLite.DB(f)
    tables = DBInterface.execute(db, "SELECT name FROM sqlite_master WHERE type='table'") |> DataFrame
    dbInfo = DBInterface.execute(db, "SELECT * FROM dbInfo") |> DataFrame
    metadata = Dict()
    metadata["version"] = dbInfo.version
    #deriveDepth = SQLite.execute(db, "SELECT * FROM deriveDepth")
    channels = DBInterface.execute(db, "SELECT * FROM channels") |> DataFrame
    channels = channels[channels.isMeasured.==1, :]
    #?data = SQLite.execute(db, "SELECT channel01 FROM data limit 3")# |> DataFrame
    data = DBInterface.execute(db, "SELECT * FROM data order by tstamp") |> DataFrame
    oad(debug, first(data, 2))
    oad(debug, channels)
    channel = [@sprintf("channel%02d", id) for id in channels.channelID]
    channelName = lowercase.(channels.longName)
    rename_dict = Dict()
    for i in eachindex(channelName)
        rename_dict[Symbol(channel[i])] = Symbol(channelName[i])
    end
    oad(debug, rename_dict)
    for key in keys(rename_dict)
        oad(debug, "$key -> $(rename_dict[key])")
        rename!(data, key => rename_dict[key])
    end
    data.time = unix2datetime.(data.tstamp / 1000.0)
    data = select(data, Not(:tstamp))
    data.salinity = gsw_sp_from_c.(data.conductivity, data.temperature, data.pressure)
    data.salinity[data.salinity.<10.0] .= NaN
    data.salinity[data.salinity.>40.0] .= NaN
    #plot(data.salinity)
    if "geodata" in tables.name
        println("FIXME: do something with the 'geodata' table (sample shown next)")
        geodata = DBInterface.execute(db, "SELECT * FROM geodata") |> DataFrame
        println(first(geodata, 3))
    end
    model = "?"
    serial_number = "?"
    if "instruments" in tables.name
        oad(debug, "    reading 'instruments'")
        instruments = DBInterface.execute(db, "SELECT * FROM instruments") |> DataFrame
        model = instruments.model
        serial_number = instruments.serialID[1]
    end
    metadata["model"] = model
    metadata["serial_number"] = serial_number
    # FIXME: this could go in a new method that takes
    # metadata::Dict, data::Vector{Real} as args, and adds
    # these things if they are not present
    data.SA = gsw_sa_from_sp.(data.salinity, data.pressure, -63, 40)
    data.CT = gsw_ct_from_t.(data.SA, data.temperature, data.pressure)
    data.sigma0 = gsw_sigma0.(data.SA, data.CT)
    data.spiciness0 = gsw_spiciness0.(data.SA, data.CT)
    metadata["longitude"] = -63
    metadata["latitude"] = 40
    Ctd(metadata, data)
end


ctd = read_ctd_rsk_trial("~/git/oce/create_data/rsk/060130_20150904_1159.rsk", debug=1)


toc(ctd)

pS = plot_profile(ctd, which="salinity");
pT = plot_profile(ctd, which="temperature");
pTS = plot_TS(ctd);
ppt = plot(ctd.data.time, ctd.data.pressure)
l = @layout [a b; c d]
plot(pS, pT, ppt, pTS, layout=l)
println(ctd.metadata["serial_number"])

# A = plot(ctd.data.time, ctd.data.pressure)
# hline!([12.0], color=:red)
# #mean(ctd.data.pressure[1:50])
# 
# B = plot(ctd.data.time, ctd.data.conductivity)
# C = plot(ctd.data.time, ctd.data.temperature)
# plot(A, B, C, layout=(3, 1))
# 
# ctd.data.pressure .> 10

println("FIXME: add way to isolate downcast")
println("FIXME: add way to fine and remove atm pressure")
