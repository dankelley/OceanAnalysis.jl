using Downloads, TiffImages, NCDatasets, Plots, ColorSchemes, Printf
using DataStructures: OrderedDict
using Interpolations: interpolate, scale

# Next is used in constructing filenames on topography server
const TOPO_DATABASE = "27ETOPO_2022_v1"

"""
    get_topography(name::Symbol=:global_coarse; debug::Integer=0)

Access a built-in topography dataset.

The only valid choice for `name` is `:global_coarse`, which returns a world
view at resolution of 30 minutes, i.e. with grid cells near the equator
spanning approximately 30 nautical miles.

See also [`read_topography`](@ref).

"""
function get_topography(name::Symbol=:global_coarse; debug::Integer=0)
    oad(debug, "get_topography(name) BEGIN")
    dir = dirname(dirname(pathof(OceanAnalysis)))
    if name == :global_coarse
        rval = joinpath(dir, "data", "topo_180W_180E_90S_90N_30min_netcdf.nc")
    else
        throw(ArgumentError("expecting 'name' to be :global_coarse, but it is $(repr(name))"))
    end
    oad(debug, "END get_topography()")
    rval
end
export get_topography


"""
    read_topography(filename::String; debug::Integer = 0)::Topography

Read a topography file that is in NetCDF format. The return value stores
longitude in `rval.metadata["longitude"]`, latitude in
`rval.metadata["latitude"]`, and depth in `rval.data`. Note that the depth
matrix is transposed, to make it easier to plot.

See also [`get_topography`](@ref).

# Arguments

- `filename` a String holding a topographic file, as downloaded
with [`get_topography`](@ref).

# Keywords

- `debug` an integer value indicating whether to print messages during processing. By default, this is 0, meaning to work quietly.

# Examples

```julia
# Plot world view of ocean depth
using OceanAnalysis, Plots
topo_file = get_topography(:global_coarse);
topo = read_topography(topo_file);
water_depth = -topo.data / 1000.0; # depth (i.e. negative height) in km
water_depth[water_depth .< 0.0] .= NaN; # trim land
heatmap(topo.metadata["longitude"], topo.metadata["latitude"], water_depth,
    asp=1.0, framestyle=:box, xlims=[-180,180], ylims=[-90,90],
    color=cgrad(:deep, rev=false), dpi=300)
cl = coastline();
plot!(cl.data.longitude, cl.data.latitude, color=:black, legend=false, linewidth=0.5)
```
"""
function read_topography(filename::String; debug::Integer=0)::Topography
    filename = expanduser(filename)
    oad(debug, "read_topography(\"", filename, "\", ...) START")
    NCDataset(filename, "r") do nc
        oad(debug, "  about to read topography data.")
        metadata = Dict()
        metadata["filename"] = filename
        # we need to copy because of how NCDataset works
        metadata["longitude"] = copy(nc["lon"])
        metadata["latitude"] = copy(nc["lat"])
        k = keys(nc)
        oad(debug, "  keys in NetCDF file: $k")
        # We transpose the topography matrix.
        if "Band1" in k
            data = copy(Float64.(replace(nc["Band1"], missing => NaN)))'
        elseif "z" in k
            # This was noticed in the code on 2026-05-10, but I think
            # it was an error.  For more on this, see the issue at
            # https://github.com/dankelley/OceanAnalysis.jl/issues/84
            data = copy(Float64.(replace(nc["z"], missing => NaN)))'
        else
            error("neither 'Band1' nor 'z' is present in this NetCDF file")
        end
        oad(debug, "  matrix dimension: ", size(data))
        oad(debug, "END read_topography()")
        return Topography(metadata, data)
    end
end
export read_topography



"""
    get_topography(west::Real, east::Real,
        south::Real, north::Real; resolution::Real=4.0, destdir::String = ".",
        server::String = "https://gis.ngdc.noaa.gov", debug::Integer = 0)::String

Download and cache a topography file, returning the name of that file.

The data source is a NOAA server that holds the ETOPO1 dataset (see Amante and
Eakins, 2009, for an introduction to the data and see Pante and Simon-Bouhet,
2013, for code that queries a server in a manner similar to that used here).
Based on the region and resolution arguments of the present function, a
potential name for downloaded data is constructed. Then, if no file of that
name is present in the provided destination directory, then the NOAA server is
queried to get the data, and the results are stored in the filename. Whether a
new download is required or not, the function returns the name of the local
data file; thus, the function can both download and cache topographic data.

# Arguments

- `west` western boundary of focus region, in the -180° to 180° range.
- `east` eastern boundary of focus region, in the -180° to 180° range.
- `south` southern boundary of focus region, in the -90° to 90° range.
- `north` northern boundary of focus region, in the -90° to 90° range.

# Keywords

- `resolution` the resolution of the returned grid, in minutes. By default,
  this is 4 minutes, or about 7.4 km in the north-south direction. Note that
  values below 0.5 are snapped to 0.25, and values between 0.5 and 1.0 are
  snapped to 0.5.

- `destdir` a String giving the name of the directory into which to place the
  downloaded file.

- `server` a String naming the server. By default, this is
  `"https://gis.ngdc.noaa.gov"`, which is (as of writing) the only server that
  provides such files

- `debug` an integer value indicating whether to print messages during
  processing. By default, this is 0, meaning to work quietly.

# Return

`get_topography` returns the name of the downloaded file.


# References

1. Amante, C. and B.W. Eakins, 2009. ETOPO1 1 Arc-Minute Global Relief Model:
   Procedures, Data Sources and Analysis. NOAA Technical Memorandum NESDIS
   NGDC-24. National Geophysical Data Center, NOAA. doi:10.7289/V5C8276M

2. Pante, Eric, and Benoit Simon-Bouhet. "Marmap: A Package for Importing,
   Plotting and Analyzing Bathymetric and Topographic Data in R." PLoS ONE 8,
   no. 9 (2013): e73051. doi:10.1371/journal.pone.0073051. (The package
   referenced was updated on 2025-Aug-2; for the query generation, see the
   `fetch` function of that package's source code in `R/getNOAA.bathy`.

3. API
   https://gis.ngdc.noaa.gov/arcgis/help/en/rest/services-reference/enterprise/export-image/

"""
function get_topography(west::Real, east::Real,
    south::Real, north::Real; resolution::Real=4.0, destdir::String=".",
    server::String="https://gis.ngdc.noaa.gov", debug::Integer=0)::String
    oad(debug, "get_topography(west=$west," *
               ", east=$east" *
               ", south=$south" *
               ", north=$north" *
               ", resolution=$resolution" *
               ", destdir='$destdir'" *
               ", server='$server') ... START"
    )
    if resolution < 0.5
        @warn "Snapping resolution from $resolution to 0.25"
        resolution = 0.25
    elseif 0.5 < resolution < 1.0
        @warn "Snapping resolution from $resolution to 0.5"
        resolution = 0.5
    end
    oad(debug, "    query resolution: $resolution")
    if resolution == 0.25
        database = "$(TOPO_DATABASE)_15s_bed_elev"
    elseif resolution == 0.50
        database = "$(TOPO_DATABASE)_30s_bed"
    else
        database = "$(TOPO_DATABASE)_60s_bed"
    end
    oad(debug, "    query database: '$database'")
    # The +-0.005 is to get rounding down for west and south, and rounding up for east and north.
    east = round(east + 0.0005, digits=3)
    west = round(west - 0.0005, digits=3)
    south = round(south - 0.0005, digits=3)
    north = round(north + 0.0005, digits=3)
    if west > 180.0
        west -= 360.0
    end
    if east > 180.0
        east -= 360.0
    end
    wName = @sprintf("%.2f", abs(west)) * (west < 0 ? "W" : "E")
    eName = @sprintf("%.2f", abs(east)) * (east < 0 ? "W" : "E")
    sName = @sprintf("%.2f", abs(south)) * (south < 0 ? "S" : "N")
    nName = @sprintf("%.2f", abs(north)) * (north < 0 ? "S" : "N")
    oad(debug, "    query wName: $wName, eName: $eName, sName: $sName, nName: $nName")
    resolutionName = string(resolution) * "min"
    oad(debug, "    query resolutionName: $resolutionName")
    destfile = expanduser(joinpath(destdir, "topo_" * wName * "_" * eName * "_" * sName * "_" * nName * "_" * resolutionName * ".nc"))
    if isfile(destfile)
        oad(debug, "    destfile $destfile already exists, so not downloading new data")
        oad(debug, "END get_topography_file()")
        return destfile
    else
        nlon = Int64(ceil(60.0 * (east - west) / resolution))
        nlat = Int64(ceil(60.0 * (north - south) / resolution))
        url = server * "/arcgis/rest/services/" *
              "DEM_mosaics/DEM_all/ImageServer/exportImage" *
              "?bbox=" * string(west) * "," * string(south) * "," * string(east) * "," * string(north) *
              "&bboxSR=4326" *
              "&size=" * string(nlon) * "," * string(nlat) *
              "&imageSR=4326" *
              "&format=tiff" *
              "&pixelType=F32" * # was S32
              "&interpolation=+RSP_NearestNeighbor" *
              "&compression=LZ77" *
              "&renderingRule={%22rasterFunction%22:%22none%22}&mosaicRule=" *
              "{%22where%22:%22Name=%" * database * "%27%22}" *
              "&f=image"
        oad(debug, "    about to download $url")
        (tiff_file, io) = mktemp()
        close(io)
        try
            Downloads.download(url, tiff_file)
        catch
            rm(tiff_file)
            error("Download failed from url='$url'")
        end
        oad(debug, "    downloaded as temporary TIFF file $tiff_file")
        #img = Float64.(TiffImages.load(tiff_file))
        z = Float64.(TiffImages.load(tiff_file))
        rm(tiff_file)
        oad(debug, "    converted TIFF data to matrix format")
        nlat, nlon = size(z)
        oad(debug, "    removed temporary TIFF file")
        # flip vertically
        z = z[end:-1:1, :]
        oad(debug, "    fliped matrix north-to-south")
        # set up longitude and latitude using size of image downloaded. But that
        # means the lon and lat might be slightly off, I think. FIXME.
        lon = range(west, east, length=nlon) # FIXME: are these limits correct, though?
        lat = range(south, north, length=nlat)
        nc = NCDataset(destfile, "c")
        oad(debug, "    created NetCDF file $destfile")
        defDim(nc, "lon", nlon)
        lon_var = defVar(nc, "lon", lon, ("lon",),
            attrib=OrderedDict("units" => "degrees_east",
                "long_name" => "longitude"))
        oad(debug, "    stored lon in NetCDF file")
        defDim(nc, "lat", nlat)
        lat_var = defVar(nc, "lat", lat, ("lat",),
            attrib=OrderedDict("units" => "degrees_north",
                "long_name" => "latitude"))
        oad(debug, "    stored lat in NetCDF file")
        z_var = defVar(nc, "z", Float64, ("lon", "lat"))
        z_var.attrib["units"] = "meters"
        z_var[:, :] = z'
        oad(debug, "    stored z (the topography matrix) in NetCDF file")
        close(nc)
        oad(debug, "    closed NetCDF file")
        oad(debug, "END get_topography_file()")
        return destfile
    end
end
export get_topography

"""
    plot_topography(topo::Topography;
        xlims=:auto, ylims=:auto, tickdirection=:out,
        domain=:sea, color=:land_sea, clim=:auto,
        draw_coastline=true, land_color=:bisque3, sea_color=:lightblue,
        debug::Integer=0, kwargs...)

Draw a `heatmap` image of topography.

The `domain` argument tells whether to display both land and sea values, or
just land, or just sea. The default is to plot just the sea, with land a light
brown color. The `aspect_ratio` argument should not be specified as part of
`kwargs...`, because this function sets a reasonable default, based on the latitude
at the centre of the plot.

```julia
# Waters near Prince Edward Island, Canada
using OceanAnalysis
topo_file = get_topography(-64.8, -61.5, 45.6, 47.2, resolution=1)
topo = read_topography(topo_file)
plot_topography(topo)
```
"""
function plot_topography(topo::Topography;
    xlims=:auto, ylims=:auto, tickdirection=:out,
    domain=:sea, color=:land_sea, clim=:auto,
    draw_coastline=true, land_color=:bisque3, sea_color=:lightblue,
    debug::Integer=0, kwargs...)
    oad(debug, "plot_topography() BEGIN")
    domain in (:sea, :land, :both) || throw(ArgumentError("domain $(repr(domain)) not permited; use :sea, :land, or :both"))
    oad(debug, "    domain: :", domain)
    oad(debug, "    color: :", color)
    oad(debug, "    clim: :", clim)
    longitude = copy(topo["longitude"])
    latitude = copy(topo["latitude"])
    data = copy(topo.data)
    aspect_ratio = 1.0 / cos(0.5 * (latitude[1] + latitude[end]) * pi / 180.0)
    if xlims == :auto
        xlims = extrema(longitude)
    end
    if ylims == :auto
        ylims = extrema(latitude)
    end
    oad(debug, "    data extrema: ", extrema(filter(!isnan, data)))
    if domain == :sea
        data .= -data
        data[data.<0.0] .= NaN
        oad(debug, "    setting land values to NaN")
        if color == :land_sea
            #color = :deep # [get(ColorSchemes.topo, i) for i in 0.0:0.6/1000:0.4]
            oad(debug, "    setting colorscheme to reversed first half of :topo")
            color = [get(ColorSchemes.topo, i) for i in 0.5:-0.6/1000:0.0]
        end
    elseif domain == :land
        data[data.<0.0] .= NaN
        oad(debug, "    setting sea values to NaN")
        if color == :land_sea
            #oad(debug, "    setting colorscheme to cgrad(:turbid,rev=true)")
            #color = cgrad(:turbid, rev=true)
            oad(debug, "    setting colorscheme to second half of :topo")
            color = [get(ColorSchemes.topo, i) for i in 0.5:0.6/1000:1.0]
        end
    elseif domain == :both
        if color == :land_sea
            oad(debug, "    setting colorscheme to :topo")
            color = :topo
        end
    end
    if clim == :auto
        if domain == :both
            clim = maximum(abs.(filter(!isnan, data))) .* (-1.0, 1.0)
        else
            clim = extrema(filter(!isnan, data))
        end
        oad(debug, "    clim defaulting to ", clim)
    end
    if domain == :sea
        background_color_inside = land_color
    elseif domain == :land
        background_color_inside = sea_color
    else
        background_color_inside = :transparent
    end
    #println("kwargs... ", kwargs...)
    p = heatmap(longitude, latitude, data,
        background_color_inside=background_color_inside,
        xlims=xlims, ylims=ylims, aspect_ratio=aspect_ratio,
        color=color, clim=clim, framestyle=:box, tickdirection=tickdirection; kwargs...)
    if draw_coastline
        oad(debug, "    plotting the coastline")
        cl = coastline()
        plot!(p, cl.data.longitude, cl.data.latitude, lw=0.5, seriestype=:path, color=:black, legend=false; kwargs...)
    end
    oad(debug, "END plot_topography()")
    p
end
export plot_topography


"""
    interpolate_topography(longitude, latitude, topo::Topography)

Interpolate topographic elevation to specified locations.

# Arguments

- `longitude` Vector of longitudes
- `latitude` Vector of latitudes
- `topo` a Topography object, e.g. as read by [`read_topography`](@ref).

# Return value

A vector of elevations above mean sea level (or whatever is the datum
of the `topo` object).

# Examples

```julia
using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "topo_180W_180E_90S_90N_30min_netcdf.nc")
topo = read_topography(file)
A = plot_topography(topo)
vline!([-63], c=:magenta)
lats = range(extrema(topo["latitude"])..., length=100)
lons = repeat([-63.0], 100)
z = interpolate_topography(lons, lats, topo)
B = plot(lats, z, label=false)
hline!([0.0], label=false)
plot(A, B)
```
"""
function interpolate_topography(longitude, latitude, topo::Topography)
    length(longitude) == length(latitude) || error("lengths of latitude and longitude are unequal")
    lon = topo["longitude"]
    lat = topo["latitude"]
    all(lon[1] .<= longitude .<= lon[end]) || error("some longitudes are offscale")
    all(lat[1] .<= latitude .<= lat[end]) || error("some latitudes are offscale")
    lon_range = range(lon[1], lon[end], length(lon))
    lat_range = range(lat[1], lat[end], length(lat))
    itp = interpolate(topo.data, BSpline(Linear()))
    sitp = scale(itp, lat_range, lon_range)
    sitp.(latitude, longitude)
end
export interpolate_topography

