using SQLite
using Dates: unix2datetime
using DataFrames
using GibbsSeaWater

"""
    read_rsk(file; patm=:file, longitude=-30.0, latitude=30.0, debug=0)

Read a Ruskin file, converting the file pressure to sea pressure by subtracting
`patm`, computing salinity from conductivity in the file. Once this
is done the values of `salinity`, `temperature` and `pressure` are passed
to [`as_ctd`](@ref), along with `longitude` and `latitude`, along
with the flag `add_teos` set to true, so that TEOS-10 variables
`SA`, `CT`, `sigma0` and `spiciness0` will also be stored in
the returned value.

# Arguments

- `file` a String naming a Ruskin file (normally, a file ending in `.rsk`).

# Keywords

- `patm` either the symbol `:file`, meaning to get this value from the file,
  or a numeric value to be used instead.

- `longitude` a numeric value giving the longitude, in the -180 to +180 convention.
  This is used in computing TEOS-10 variables and, since rsk files do
  not tend to store longitude, it is important to set a value that is
  at least approximately near the sampling site.

- `latitude` as with `longitude`, but for latitude in -90 to +90 convention.

- `debug` an Integer controlling the verbosity of the function. If set to 0,
  the function works silently.  If it is a positive number, some information
  is printed during processing.

# Return value

A Ctd object.
"""
function read_rsk(file; patm=:file, longitude=-30.0, latitude=30.0, debug=0)
    oad(debug, "read_rsk() START")
    db = SQLite.DB(file)
    if patm == :file
        patm = DataFrame(DBInterface.execute(db, "SELECT * FROM parameters"))[1, :atmosphere]
        oad(debug, "    patm: $patm (as read from the file)")
    else
        oad(debug, "    patm: $patm (as supplied as an argument)")
    end
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
        longitude=longitude, latitude=latitude,
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

