using SQLite
using Dates: unix2datetime
using DataFrames
using GibbsSeaWater
using OceanAnalysis
using GLMakie # or CairoMakie

"""
    read_rsk(file; debug=0)

Read a Ruskin file.

# Arguments

- `file` a String naming a Ruskin file (normally, a file ending in `.rsk`).

# Keywords

- `debug` an Integer controlling the verbosity of the function. If set to 0,
  the function works silently.  If it is a positive number, some information
  is printed during processing.

# Return value

A Ctd object.
"""
function read_rsk(file; debug=0)
    oad(debug, "read_rsk() START")
    db = SQLite.DB(file)
    patm = DataFrame(DBInterface.execute(db, "SELECT * FROM parameters"))[1, :atmosphere]
    oad(debug, "    patm: $patm")
    db_version = DataFrame(DBInterface.execute(db, "SELECT * FROM dbinfo"))[1, :version]
    oad(debug, "    db_version: $db_version")
    tmp = DataFrame(DBInterface.execute(db, "SELECT * FROM instruments"))[1, :]
    serial_number = tmp.serialID
    oad(debug, "    serial_number: $serial_number")
    instrument = tmp.model
    oad(debug, "    instrument: $instrument")
    #tables = SQLite.tables(db)
    #println(tables)
    #for table in tables
    #    println(table)
    #end
    data = DBInterface.execute(db, "SELECT * FROM data") |> DataFrame
    # Sort by time, since the data are not in order
    sort!(data, :tstamp)
    channels = DBInterface.execute(db, "SELECT * FROM channels") |> DataFrame
    channels_measured = channels[channels.isMeasured .== 1, :]
    # Rename data
    original_names = names(data)
    for name in names(data)
        if occursin("channel", name)
            channelID = parse(Int64, replace(name, "channel" => ""))
            new_name = lowercase(channels_measured[channelID .== channels_measured.channelID, :longName][1])
            rename!(data, name => new_name)
            oad(debug, "    renamed '$name' column as '$new_name'")
        end
    end
    "temperature" in names(data) || error("cannot determine temperature, given $(original_names)")
    "pressure" in names(data) || error("cannot determine pressure, given $(original_names)")
    # subtract atmospheric pressure (and rename)
    rename!(data, "pressure" => "pressure_total")
    oad(debug, "    subtracting atmospheric pressure from recorded pressure")
    data[:, :pressure] = data.pressure_total .- patm
    # Convert to time (not sure this is needed generally, but doing it here for testing)
    oad(debug, "    computing time from the timestamp (which is in milliseconds)")
    data[:, :time] = unix2datetime.(data.tstamp ./ 1000.0)
    # add salinity
    oad(debug, "    adding salinity")
    sp = gsw_sp_from_c.(data.conductivity, data.temperature, data.pressure)
    sp[sp .== 9.0e15] .= NaN # gsw_ functions use this value for problem cases
    data[:, :salinity] = sp
    rval = as_ctd(data.salinity, data.temperature, data.pressure,
        add_teos=true, debug=increment_debug(debug))
    rval.metadata["db_version"] = db_version
    rval.metadata["patm"] = patm
    rval.metadata["serial_number"] = serial_number
    rval.metadata["instrument"] = instrument
    # Add some columns manually (FIXME: can the instrument make more columns?)
    rval.data[:, :time] = data.time
    rval.data[:, :conductivity] = data.conductivity
    rval.data[:, :pressure_total] = data.pressure_total
    oad(debug, "END read_rsk()")
    return rval
end
export read_rsk

