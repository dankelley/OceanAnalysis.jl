"""
    read_nonna(filename::String)

Read a NONNA bathymetric file.

Such files for Canadian waters are available at
https://data.chs-shc.ca/dashboard/map, through a somewhat confusing interface.

FIXME: consider making a NONNA object type (perhaps) and write a function to plot them.

# Examples

```julia
using OceanAnalysis, Plots
x,y,bathy = read_nonna("NONNA10_4460N06340W.tiff")
heatmap(x, y, bathy, color=:turbo,
    framestyle=:box, tickdirection=:out,
    aspect_ratio=1.0, size=(800, 800),
    xlab="Local Easting [m]", ylab="Local Northing [m]")
```
"""
function read_nonna(filename::String)
    #<> using FileIO, TiffImages, Plots
    #place = "East Lawrencetown"
    #url = "https://data.chs-shc.ca/dashboard/map"
    f = "NONNA10_4460N06340W.tiff"
    img = TiffImages.load(f)
    ifd = img.ifds[1]
    # FIXME: could grab all the elements and put them into metadata
    #<> sample_time = ifd[TiffImages.DATETIME].data
    #<> tmp = ifd[TiffImages.MODELTIEPOINT].data
    #<> model_tie_point_lon = tmp[4]
    #<> model_tie_point_lat = tmp[5]
    # Address missing-value codes (for land or bad data)
    d = Float64.(img)
    bad = d .> 1.0e38
    d[bad] .= NaN
    # Flip the y coordinates so that south is at the bottom of the image
    d = reverse(d, dims=1)
    s = size(d)
    x = 1:s[1]
    y = 1:s[2]
    # FIXME consider making an object type
    x, y, d
end

