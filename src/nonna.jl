"""
    read_nonna(filename::String)

Read a NONNA (NON-NAvigational) bathymetric file.

The Canadian Hydrographic Service provides access to high-resolution
bathymetric data for some Canadian waters at
https://data.chs-shc.ca/dashboard/map. (This is a GUI-oriented site, and it is
somewhat challenging to navigate.) Files are available at both 10-m and 100-m
resolution and in a variety of formats. The present function handles only the
GeoTIFF format.

# Return value

This returns a [`Nonna`](@ref) object that holds `metadata` and `data`. The
`metadata` item is a Dict that holds `easting`, `northing` (both in metres) and
some other elements.  The `data` item is a Matrix of the height (in metres)
above a nominal sea-level surface.


# Examples

```julia
using OceanAnalysis, Plots
# Region near East Lawrencetown Beach Provincial Park
n = read_nonna(expanduser("~/data/nonna/NONNA10_4460N06340W.tiff"));
heatmap(n["longitude"], n["latitude"], n.data, color=:turbo,
    framestyle=:box, tickdirection=:out, dpi=300,
    aspect_ratio=1.0, size=(800, 800))
```
"""
function read_nonna(filename::String)
    I = gmtread(filename)
    metadata = Dict()
    metadata["longitude"] = I.x
    metadata["latitude"] = I.y
    data = I.z
    metadata["filename"] = filename
    metadata["projection"] = I.proj4
    metadata["inc"] = I.inc
    Nonna(metadata, data)
end
export read_nonna

