using SQLite, DataFrames, Plots, Dates, Printf, Statistics

"""
    read_ctd_rsk(filename::String; add_teos::Bool=true,
        longitude=-60.0, latitude=40.0, debug::Int64=0)

Read a CTD file from an RBR instrument.

The sqlite scheme is used in such files, so the present function relies
on the `SQLite` package. Only a fraction of the tables within the file
are read in this version of the function.  The main tables that are
examined are: `data`, which holds the data; `channels`, which is used
to rename the elements in `data`; and (if present) `geodata`, which
may hold information on the sampling location.

If `add_teos` is true, then the TEOS10 quantities `CT`, SA`, `sigma0` and
`spiciness0` are computed.  These require knowledge of the sampling location,
which is inferred from the `geodata` table (if it exists) or from
the function arguments named `longitude` and `latitude`, otherwise. (The
default values of these parameters correspond to the western North Atlantic.)

# Examples
```juliadoc
using OceanAnalysis, Plots
ctd = read_ctd_rsk("~/git/oce/create_data/rsk/060130_20150904_1159.rsk")
pS = plot_profile(ctd, which="salinity");
pT = plot_profile(ctd, which="temperature");
pTS = plot_TS(ctd);
ppt = plot(ctd.data.time, ctd.data.pressure)
plot(pS, pT, ppt, pTS, layout=(2,2))
```
"""
function read_ctd_rsk(filename::String; add_teos::Bool=true,
    longitude=-60.0, latitude=40.0, debug::Int64=0)
    oad(debug, "read_ctd_rsk() START")
    filename = expanduser(filename)
    # FIXME: how do we close the db?
    db = SQLite.DB(filename)
    oad(debug, "    reading 'sqlite_master' table (to get names of other tables)")
    tables = DBInterface.execute(db, "SELECT name FROM sqlite_master WHERE type='table'") |> DataFrame
    oad(debug, "    reading 'dbInfo' table (to learn about the software version, etc)")
    dbInfo = DBInterface.execute(db, "SELECT * FROM dbInfo") |> DataFrame
    metadata = Dict()
    metadata["version"] = dbInfo.version
    #deriveDepth = SQLite.execute(db, "SELECT * FROM deriveDepth")
    oad(debug, "    reading 'channels' table (to learn about the data columns)")
    channels = DBInterface.execute(db, "SELECT * FROM channels") |> DataFrame
    channels = channels[channels.isMeasured.==1, :]
    oad(debug, "    reading 'data' table (to get the columnar data)")
    data = DBInterface.execute(db, "SELECT * FROM data order by tstamp") |> DataFrame
    channel = [@sprintf("channel%02d", id) for id in channels.channelID]
    channelName = lowercase.(channels.longName)
    rename_dict = Dict()
    for i in eachindex(channelName)
        rename_dict[Symbol(channel[i])] = Symbol(channelName[i])
    end
    for key in keys(rename_dict)
        oad(debug, "        naming channel with ID=", parse(Int, replace(string(key), "channel" => "")),
            " as ", rename_dict[key])
        rename!(data, key => rename_dict[key])
    end
    oad(debug, "    converting 'tstamp' column to 'time' (and deleting 'tstamp')")
    data.time = unix2datetime.(data.tstamp / 1000.0)
    data = select(data, Not(:tstamp))
    oad(debug, "    calculating 'salinity' from 'conductivity', 'temperature' and 'pressure'")
    data.salinity = gsw_sp_from_c.(data.conductivity, data.temperature, data.pressure)
    oad(debug, "        setting salinities under 10 g/kg to NaN")
    data.salinity[data.salinity.<10.0] .= NaN
    oad(debug, "        setting salinities over 40 g/kg to NaN")
    data.salinity[data.salinity.>40.0] .= NaN
    if "geodata" in tables.name
        oad(debug, "        reading 'geodata' table (FIXME: not sure on contents' names)")
        geodata = DBInterface.execute(db, "SELECT * FROM geodata") |> DataFrame
        longitude = geodata.longitude
        latitude = geodata.latitude
    end
    if "instruments" in tables.name
        oad(debug, "    reading 'instruments' table")
        instruments = DBInterface.execute(db, "SELECT * FROM instruments") |> DataFrame
        model = instruments.model
        serial_number = instruments.serialID[1]
    else
        model = "?"
        serial_number = "?"
    end
    oad(debug, "    adding 'model' to metadata")
    metadata["model"] = model
    oad(debug, "    adding 'serial_number' to metadata")
    metadata["serial_number"] = serial_number
    # FIXME: this could go in a new method that takes
    # metadata::Dict, data::Vector{Real} as args, and adds
    # these things if they are not present
    if add_teos
        oad(debug, "    adding teos-10 variables because add_teos is true")
        oad(debug, "        adding 'SA' column to data")
        data.SA = gsw_sa_from_sp.(data.salinity, data.pressure, -63, 40)
        oad(debug, "        adding 'CT' column to data")
        data.CT = gsw_ct_from_t.(data.SA, data.temperature, data.pressure)
        oad(debug, "        adding 'sigma0' column to data")
        data.sigma0 = gsw_sigma0.(data.SA, data.CT)
        oad(debug, "        adding 'spiciness0' column to data")
        data.spiciness0 = gsw_spiciness0.(data.SA, data.CT)
    end
    oad(debug, "    adding 'longitude' to metadata")
    metadata["longitude"] = longitude
    oad(debug, "    adding 'latitude' to metadata")
    metadata["latitude"] = latitude
    rval = Ctd(metadata, data)
    oad(debug, "END read_ctd_rsk()")
    rval
end
