using SQLite, DataFrames, Plots, Dates, Printf, Statistics

"""
    read_ctd_rsk(filename::String; add_teos::Bool=true,
        atmospheric_pressure=missing, longitude::Real=-60.0, latitude::Real=40.0,
        debug::Integer=0)

Read a CTD file from an RBR instrument.

These files store data in sqlite format, which the present function
handles with the `SQLite` package. Only a subset of the tables within 
RBR files are read in this version of the function.  The main such
tables are: `data`, which holds the data; `channels`, which is used
to rename the elements in `data`; and (if present) `geodata`, which
may hold information on the sampling location. Other tables are consulted
to learn things like the serial number of the instrument. Some
information on the reading process is printed if you call the function
with `debug=1`.

Note that RBR files typically record 'gauge' pressure, which is the
sum of atmospheric pressure and the sea pressure. Since oceanographic
calculations are typically formulated in terms of sea pressure, so the
pressure data stored in RBR files is not inserted into the value
returned by this function.  Instead, the returned value is set to
pressure stored in the file minus atmospheric pressure.  The value
of atmospheric pressure is taken from the data file if it holds a
table called `deriveDepth`. If such a table is not found, and if
the `atmosphericPressure` argument was not supplied, a default of 10.1325
dbar is used.  However, if that argument is supplied, then it
supercedes a value stored in the file,

If `add_teos` is true, then the TEOS10 quantities `CT`, `SA`, `sigma0` and
`spiciness0` are computed.  These require knowledge of the sampling location,
which is inferred from the `geodata` table (if it exists) or from
the function arguments named `longitude` and `latitude`, otherwise. (The
default values of these parameters specify a position in the western
North Atlantic.)

Note that these data files are in a raw form from the instrument, and 
so some trimming to the downcast portion(s) may be needed.  Such
features are not yet provided in this package.

# Examples
```julia
using OceanAnalysis, Plots
ctd = read_ctd_rsk("~/git/oce/create_data/rsk/060130_20150904_1159.rsk");
Sp = plot_profile(ctd, which="salinity");
Tp = plot_profile(ctd, which="temperature");
TS = plot_TS(ctd);
pt = plot(ctd.data.time, ctd.data.pressure);
plot(Sp, Tp, pt, TS, layout=(2,2))
```
"""
function read_ctd_rsk(filename::String; add_teos::Bool=true,
    atmospheric_pressure=missing, longitude::Real=-60.0, latitude::Real=40.0,
    debug::Integer=0)
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
        oad(debug, "        reading 'geodata' table (which supercedes 'longitude' and 'latitude' arguments)")
        geodata = DBInterface.execute(db, "SELECT * FROM geodata") |> DataFrame
        longitude = geodata.longitude
        latitude = geodata.latitude
    end
    if "deriveDepth" in tables.name
        if ismissing(atmospheric_pressure)
            oad(debug, "    reading 'deriveDepth' table (to find 'atmospheric_pressure' argument)")
            deriveDepth = DBInterface.execute(db, "SELECT * FROM deriveDepth") |> DataFrame
            atmospheric_pressure = deriveDepth.atmosphericPressure
        else
            oad(debug, "    ignoring atmospheric pressure stored in the 'deriveDepth' table, because user supplied a value as an argument")
        end
    else
        if ismissing(atmospheric_pressure)
            atmospheric_pressure = 10.1325
            oad(debug, "    file has no 'deriveDepth' table, and atmospheric_pressure not provided, so latter defaults to ", atmospheric_pressure, " dbar")
        end
    end
    if "instruments" in tables.name
        oad(debug, "    reading 'instruments' table (from which we get 'model' and 'serial_number')")
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
    oad(debug, "    adding 'atmospheric_pressure' to metadata")
    metadata["atmospheric_pressure"] = atmospheric_pressure
    oad(debug, "    subtracting ", atmospheric_pressure, " dbar from file pressure")
    data.pressure = data.pressure .- atmospheric_pressure
    oad(debug, "    adding 'longitude' to metadata")
    metadata["longitude"] = longitude
    oad(debug, "    adding 'latitude' to metadata")
    metadata["latitude"] = latitude
    rval = Ctd(metadata, data)
    if add_teos
        rval = set_teos(rval)
    end
    oad(debug, "END read_ctd_rsk()")
    rval
end
