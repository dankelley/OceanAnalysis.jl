"""
    read_nonna(filename::String)

Read a NONNA bathymetric file.

Such files for Canadian waters are available at
https://data.chs-shc.ca/dashboard/map, through a somewhat confusing interface that requires GUI operations.

# Return Value

This returns a [`Nonna`](@ref) object that holds `metadata` and `data`. The `metadata` item is a Dict that holds `easting`, `northing` (both in metres) and some other elements.  The `data` item is a Matrix of the height (in metres) above a nominal sea-level surface.


# Examples

```julia
using OceanAnalysis, Plots
n = read_nonna(expanduser("~/data/nonna/NONNA10_4460N06340W.tiff"));
heatmap(n["northing"], n["easting"], n.data, color=:turbo,
    framestyle=:box, tickdirection=:out,
    aspect_ratio=1.0, size=(800, 800),
    xlab="Easting [m]", ylab="Northing [m]")
```
"""
function read_nonna(filename::String, grid_size::Float64=10.0)
    #url = "https://data.chs-shc.ca/dashboard/map"
    f = "NONNA10_4460N06340W.tiff"
    img = TiffImages.load(filename)
    metadata = Dict()
    # FIXME: put all tags into metadata? (Tricky, as interface is changeable.)
    ifd = img.ifds[1]
    metadata["filename"] = filename
    metadata["grid_size"] = grid_size
    metadata["sample_time"] = ifd[TiffImages.DATETIME].data
    tmp = ifd[TiffImages.MODELTIEPOINT].data
    metadata["model_tie_point_lon"] = tmp[4]
    metadata["model_tie_point_lat"] = tmp[5]
    # Address missing-value codes (for land or bad data)
    data = Float64.(img)
    bad = data .> 1.0e38
    data[bad] .= NaN
    # Flip the y coordinates so that south is at the bottom of the image
    data = reverse(data, dims=1)
    s = size(data)
    x = grid_size * range(0.0, length=s[1])
    y = grid_size * range(0.0, length=s[2])
    metadata["easting"] = x
    metadata["northing"] = y
    Nonna(metadata, data)
end

