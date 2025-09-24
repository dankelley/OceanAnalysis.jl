using Downloads, TiffImages, NCDatasets, Plots
using DataStructures: OrderedDict
using Printf

"""
    get_topography_file(name::Symbol=:global_coarse; debug::Int64=0)

Access a built-in topography dataset.

The only valid choice for `name` is `:global_coarse`, which returns a world
view at resolution of 30 minutes, i.e. with grid cells near the equator
spanning approximately 30 nautical miles.

See also [`read_topography`](@ref).

"""
function get_topography_file(name::Symbol=:global_coarse; debug::Int64=0)
    oad(debug, "get_topography_file(name) BEGIN")
    dir = dirname(dirname(pathof(OceanAnalysis)))
    if name == :global_coarse
        rval = joinpath(dir, "data", "topo_180W_180E_90S_90N_30min_netcdf.nc")
    else
        error("    expecting 'name' to be :global_coarse, but :", name, " was provided")
    end
    oad(debug, "END get_topography_file()")
    rval
end

"""
    read_topography(filename::String; debug::Int64 = 0)

Read a topography file that is in NetCDF format. The return value stores
longitude in `rval.metadata["longitude"]`, latitude in
`rval.metadata["latitude"]`, and depth in `rval.data`. Note that the depth
matrix is transposed, to make it easier to plot.

See also [`get_topography_file`](@ref).

# Examples

```juliadoc
# Plot world view of ocean depth
using OceanAnalysis, Plots
topo_file = get_topography_file(:global_coarse);
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
function read_topography(filename::String; debug::Int64=0)
    filename = expanduser(filename)
    oad(debug, "read_topography(\"", filename, "\", ...) BEGIN")
    NCDataset(filename, "r") do nc
        oad(debug, "    about to read topography data.")
        metadata = Dict()
        metadata["filename"] = filename
        # FIXME: do we need to copy in a case like this?
        metadata["longitude"] = copy(nc["lon"])
        metadata["latitude"] = copy(nc["lat"])
        # Transpose because of the file setup.
        data = copy(Float64.(replace(nc["z"], missing => NaN)))'
        oad(debug, "    matrix dimension: ", size(data))
        oad(debug, "END read_topography()")
        return Topography(metadata, data)
    end
end


"""
    get_topography_file(west::Real, east::Real,
        south::Real, north::Real; resolution::Real=4.0, destdir::String = ".",
        server::String = "https://gis.ngdc.noaa.gov", debug::Int64 = 0)

Download and cache a topography file.

Topographic data are downloaded from a data server that holds the ETOPO1
dataset (see Amante and Eakins, 2009, for an introduction to the data and see
    Pante and Simon-Bouhet, 2013, for code that queries a server in a manner
        similar to that used here), and saved as a netCDF file that has a name
        that reveals the data request, if a file of that name is not already
            present on the local file system.  The return value is the name of
            the data file, and its typical use is as the filename for a call to
                [`read_topography`](@ref). Subsequent calls to
                `get_topography_file` with identical parameters will return the
                name of an already-downloaded file, without downloading a new
                copy.

The specified longitude and latitude limits are rounded to 2 digits after the
decimal place (corresponding to an equatorial footprint of approximately 1 km),
and these are used in the server request.

The region of interest is defined by a rectangle bounded by the values of
`west`, `east`, `south` and `north`. The resolution is set by the value of
`resolution`, which is minutes. The default, 4.0 minutes, corresponds to 4
nautical miles (approx. 7.4km) in the north-south direction, and less in the
east-west direction. The default values of these 5 arguments yield
a view of the Bay of Fundy region.

The value of `server` ought not to be modified by users, except perhaps
to experiment if the NOAA server changes.  (It is unlikely that merely
changing this value will help much, though, since changes tend not
to be small on these servers.)

# References

- Amante, C. and B.W. Eakins, 2009. ETOPO1 1 Arc-Minute Global Relief Model:
Procedures, Data Sources and Analysis. NOAA Technical Memorandum NESDIS
NGDC-24. National Geophysical Data Center, NOAA. doi:10.7289/V5C8276M

- Pante, Eric, and Benoit Simon-Bouhet. “Marmap: A Package for Importing,
    Plotting and Analyzing Bathymetric and Topographic Data in R.” PLoS ONE 8,
    no. 9 (2013): e73051. doi:10.1371/journal.pone.0073051.
    (The package referenced was updated on 2025-Aug-2; for
        the query generation, see the `fetch`
        function of that packages sourcecode `R/getNOAA.bathy`.
"""
function get_topography_file(west::Real, east::Real,
    south::Real, north::Real; resolution::Real=4.0, destdir::String = ".",
    server::String = "https://gis.ngdc.noaa.gov", debug::Int64 = 0)
    oad(debug, "get_topography_file(west=$west,"*
        ", east=$east"*
        ", south=$south"*
        ", north=$north"*
        ", resolution=$resolution"*
        ", destdir='$destdir'"*
        ", server='$server') ... START"
    )
    if resolution < 0.5
        resolution = 0.25
    elseif resolution < 1.0
        resolution = 0.50
    end
    oad(debug, "    query resolution: $resolution")
    if resolution == 0.25
        database = "27ETOPO_2022_v1_15s_bed_elev"
    elseif resolution == 0.50
        database = "27ETOPO_2022_v1_30s_bed"
    else
        database = "27ETOPO_2022_v1_60s_bed"
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
    destfile = expanduser(joinpath(destdir, "topo_" * wName * "_" * eName * "_" * sName * "_" * nName* "_"*resolutionName *".nc"))
    if isfile(destfile)
        oad(debug, "    destfile $destfile already exists, so not downloading new data")
        oad(debug, "read_topography_file() END")
        return destfile
    else
        nlon = Int64(ceil(60.0*(east - west) / resolution))
        nlat = Int64(ceil(60.0*(north - south) / resolution))
        url = server * "/arcgis/rest/services/"*
        "DEM_mosaics/DEM_all/ImageServer/exportImage"*
        "?bbox="* string(west)* ","* string(south) * ","* string(east) * ","* string(north)*
        "&bboxSR=4326"*
        "&size="* string(nlon)* ","* string(nlat)*
        "&imageSR=4326"*
        "&format=tiff"*
        "&pixelType=F32"* # was S32
        "&interpolation=+RSP_NearestNeighbor"*
        #"&compression=LZ77"*
        "renderingRule={%22rasterFunction%22:%22none%22}&mosaicRule="*
        "{%22where%22:%22Name=%"* database* "%27%22}"*
        "&f=image"
        oad(debug, "    about to download $url")
        (tiff_file, io) = mktemp()
        Downloads.download(url, tiff_file)
        oad(debug, "    downloaded as temporary TIFF file $tiff_file")
        #img = Float64.(TiffImages.load(tiff_file))
        z = Float64.(TiffImages.load(tiff_file))
        oad(debug, "    converted TIFF data to matrix format")
        nlat, nlon = size(z)
        rm(tiff_file)
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
                               attrib = OrderedDict("units" => "degrees_east",
                                                    "long_name" => "longitude"))
        oad(debug, "    stored lon in NetCDF file")
        defDim(nc, "lat", nlat)
        lat_var = defVar(nc, "lat", lat, ("lat",),
                               attrib = OrderedDict("units" => "degrees_north",
                                                    "lat_name" => "latitude"))
        oad(debug, "    stored lat in NetCDF file")
        z_var = defVar(nc, "z", Float64, ("lon", "lat"))
        z_var.attrib["units"] = "degrees"
        z_var[:, :] = z'
        oad(debug, "    stored z (the topography matrix) in NetCDF file")
        close(nc)
        oad(debug, "    closed NetCDF file")
        oad(debug, "read_topography_file() END")
        return destfile
    end
end

