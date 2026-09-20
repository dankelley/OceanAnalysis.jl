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
using OceanAnalysis
using ColorSchemes
using GLMakie # or CairoMakie
# Region near East Lawrencetown Beach Provincial Park
file = expanduser("~/data/nonna/NONNA10_4460N06340W.tiff")
if isfile(file)
    n = read_nonna(file);
    colormap = [get(ColorSchemes.topo, i) for i in 0.5:-0.6/1000:0.0]
    heatmap(n["longitude"], n["latitude"], -n.data', colormap=colormap)
end
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

