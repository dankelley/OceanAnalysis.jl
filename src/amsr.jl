"""
    read_amsr(filename::String, field::String="SST", debug=0)

Reads a NetCDF file containing AMSR data.

This returns a value of the [`Amsr`](@ref) type, with `metadata` containing
the `filename` along with vectors holding the `longitude` and `latitude` of
the grid.  The `data` field holds a matrix of the data element with the
indicated `name` (e.g. `name="SST"` for sea-surface temperature).

# Arguments

- `filename` a string indicating the location of the local file.

- `field` a string used to identify the data field to be extracted.  If
`field="?"` then `read_amsr` returns a vector of strings containing extractable
data.  Otherwise, if `field` names one of those items, then `read_amsr` returns
that dataset.

# Examples

```juliadoc
using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc";
d = read_amsr(f, "SST");
longitude = d.metadata["longitude"];
latitude = d.metadata["latitude"];
SST = d.data;
heatmap(longitude, latitude, SST, framestyle=:box, aspect_ratio=:equal,
    xlims=(0, 360), ylims=(-90, 90), dpi=300, size=(800, 400),
    title=f * ": SST", titlefontsize=9)
```
"""
function read_amsr(filename::String, field::String="SST", debug=0)
    filename = expanduser(filename)
    oad(debug, "read_amsr() BEGIN")
    NCDataset(filename, "r") do nc
        oad(debug, "    about to read SST.")
        if field == "?"
            return keys(nc)
        else
            metadata = Dict()
            metadata["filename"] = filename
            metadata["longitude"] = copy(nc["lon"])
            metadata["latitude"] = copy(nc["lat"])
            data = copy((Float64.(replace(nc[field], missing => NaN)))')
            oad(debug, "END read_amsr()")
            return Amsr(metadata, data)
        end
    end
end
