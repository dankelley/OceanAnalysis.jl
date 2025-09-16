"""
    read_amsr(filename::String, field::String="SST", debug=0)

Reads a NetCDF file containing AMSR data.

This returns a value of the [`Amsr`](@ref) type, with `metadata` containing
the `filename` along with vectors holding the `longitude` and `latitude` of
the grid.  The `data` field holds a matrix of the data element with the
indicated `name` (e.g. `name="SST"` for sea-surface temperature).
"""
function read_amsr(filename::String, field::String="SST", debug=0)
    filename = expanduser(filename)
    oad(debug, "read_amsr() BEGIN")
    NCDataset(filename, "r") do nc
        oad(debug, "    about to read SST.")
        metadata = Dict()
        metadata["filename"] = filename
        metadata["longitude"] = copy(nc["lon"])
        metadata["latitude"] = copy(nc["lat"])
        data = copy((Float64.(replace(nc[field], missing => NaN)))')
        oad(debug, "END read_amsr()")
        return Amsr(metadata, data)
    end
end
