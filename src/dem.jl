using Plots, Plots.PlotMeasures, Statistics, Printf
using GMT: gmtread, xy2lonlat, grdproject # will only need first 2, later

"""
    read_dem(file::String; lonlat_method::Symbol = :interpolated)

Read a digital-elevation-model file.  See also [`subset_dem`](@ref) and
[`plot_dem`](@ref) for more processing functions.

# Arguments

- `file` a String naming a TIFF file that holds DEM data.

# Keywords

- `lonlat_method` a Symbol, either `:interpolated` or `projected`. If the
  former (which is the default) then the corners are projected and then linear
  interpolation is done in between. If the latter, which is substantially slower,
  all the points in the grid are projected. The two methods disagreed in a test
  by at most the equivalent of 0.5 m distance.

- `debug` an integer that, if it exceeds 0, indicates that the function is to
  print out some intermediate steps.

# Return

`read_dem` returns an [`Dem`](@ref) object.  Its `metadata` item is a Dict
holding the `filename`, along with grid axis variables `x` and `y` that are in
the easterly and northerly directions, plus the corresponding geographical
coordinates `longitude` and `latitude`. Its `data` item is a matrix of
elevation, in metres.

# Examples

```julia
using OceanAnalysis, Plots
# Data downloaded from https://nsgi.novascotia.ca/datalocator/elevation/
file = "/Users/kelley/Downloads/1044600063500_201901_DEM/1044600063500_201901_DEM.tif"
if isfile(file)
    dem = read_dem(file)
    dem = subset_dem(dem, (-63.587, -63.552), (44.615, 44.639))
    middle_lat = dem["latitude"][div(end + 1, 2)]
    aspect_ratio = 1.0 / cos(middle_lat * pi / 180.0)
    heatmap(dem["longitude"], dem["latitude"], dem.data,
        color=:turbo, aspect_ratio=aspect_ratio,
        framestyle=:box, tickdirection=:out)
end
```

"""
function read_dem(file::String; lonlat_method::Symbol=:interpolated, debug::Int=0)
    g = gmtread(file; grid=true)
    x, y = g.x[2:end], g.y[2:end]
    z = g.z
    if lonlat_method == :projected
        geo = grdproject(g, J=g.proj4, I=true)
        lon, lat = geo.x, geo.y
        # shorten to make a match to the matrix
        lon = lon[2:end]
        lat = lat[2:end]
        if debug > 0
            ddlon = collect(extrema(diff(lon)))
            ddlat = collect(extrema(diff(lat)))
            println("ddlon=extrema(diff(lon)): $ddlon")
            println("ddlat=extrema(diff(lat)): $ddlat")
            println("diff(ddlon)/mean(ddlon): $((ddlon[2]-ddlon[1]) / mean(ddlon))")
            println("diff(ddlat)/mean(ddlat): $((ddlat[2]-ddlat[1]) / mean(ddlat))")
            println("first lon: $(first(lon, 3))")
            println("last  lon: $(last(lon, 3))")
            println("first lat: $(first(lat, 3))")
            println("last  lat: $(last(lat, 3))")
        end
    elseif lonlat_method == :interpolated
        corners = [g.x[2] g.y[end]; g.x[end] g.y[end]; g.x[end] g.y[1]; g.x[1] g.y[1]]
        proj = g.proj4
        corners_lonlat = xy2lonlat(corners, proj)
        lonlim = extrema(corners_lonlat[:, 1])
        latlim = extrema(corners_lonlat[:, 2])
        if debug > 0
            println("Longitude and latitude limits, using GMT functions:")
            println("  lonlim: $lonlim")
            println("  latlim: $latlim")
        end
        lon = range(lonlim[1]; stop=lonlim[2], length=length(g.x) - 1)
        lat = range(latlim[1]; stop=latlim[2], length=length(g.y) - 1)
    else
        error("lonlat_method is $(repr(lonlat_method)) but it must be :simple or :accurate")
    end
    metadata = Dict(
        "filename" => file,
        "dx" => g.inc[1],
        "dy" => g.inc[2],
        "proj" => g.proj4, "x" => x, "y" => y, "longitude" => lon, "latitude" => lat)
    Dem(metadata, z)
end



"""
    subset_dem(dem::Dem; lonlim::Tuple{Real,Real}, latlim::Tuple{Real,Real},
        debug::Int=0)

Subset a Dem object.

# Arguments

- `dem` a Dem object, as read by [`read_dem`](@ref), perhaps later modified by [`subset_dem`](@ref).

# Keywords

- `lonlim` a tuple holding the minimum and maximum longitude to be retained.

- `latlim` a tuple holding the minimum and maximum latitude to be retained.

- `debug` an integer that, if it exceeds 0, indicates that the function is to print out some intermediate steps.

"""
function subset_dem(dem::Dem; lonlim::Tuple{Real,Real}, latlim::Tuple{Real,Real}, debug::Int=0)
    oad(debug, "subset_dem() START")
    oad(debug, "  lonlim: $lonlim")
    oad(debug, "  latlim: $latlim")
    2 == length(lonlim) || throw(ArgumentError("lonlim must be a Vector or Tuple of length 2"))
    2 == length(latlim) || throw(ArgumentError("latlim must be a Vector or Tuple of length 2"))
    x = copy(dem["x"])
    y = copy(dem["y"])
    lon = copy(dem["longitude"])
    lat = copy(dem["latitude"])
    lon_keep = (lonlim[1] .<= lon) .& (lon .<= lonlim[2])
    lat_keep = (latlim[1] .<= lat) .& (lat .<= latlim[2])
    if debug > 0
        lonpc = 100.0 * sum(lon_keep) / length(lon_keep)
        latpc = 100.0 * sum(lat_keep) / length(lat_keep)
        oad(debug, @sprintf("  keeping %.3f%%  of longitude (len %d)", lonpc, length(lon_keep)))
        oad(debug, @sprintf("  keeping %.3f%%  of latitude (len %d)", latpc, length(lat_keep)))
    end
    metadata = copy(dem.metadata)
    metadata["x"] = x[lon_keep]
    metadata["y"] = y[lat_keep]
    metadata["longitude"] = lon[lon_keep]
    metadata["latitude"] = lat[lat_keep]
    rval = Dem(metadata, dem.data[lat_keep, lon_keep])
    oad(debug, "END subset_dem()")
    rval
end

"""
    plot_dem(dem::Dem; debug::Int=0)

# Arguments

- `dem` a Dem object

# Keywords

- `coordinates` a Symbol that indicates what to put on the axes. If this is
  `:distance` (the default) then distance (in m) is shown on the axes. Otherwise,
  if it is `:geographic` then longitude and latitude are used (with aspect ratio
  set for the middle latitude).

- `kwargs...` other arguments, passed to `heatmap`, which plots the elevation
  data.

"""
function plot_dem(dem::Dem; coordinates::Symbol=:distance, kwargs...)
    println("in plot_dem()")
    if coordinates == :distance
        heatmap(dem.metadata["x"], dem.metadata["y"], dem.data,
            aspect_ratio=1.0, framestyle=:box, tickdirection=:out, kwargs...)
    elseif coordinates == :geographic
        middle_lat = dem.metadata["latitude"][div(end + 1, 2)]
        aspect_ratio = 1.0 / cos(middle_lat * pi / 180.0)
        heatmap(dem.metadata["longitude"], dem.metadata["latitude"], dem.data,
            aspect_ratio=aspect_ratio, framestyle=:box, tickdirection=:out, kwargs...)
    else
        error("coordinates=$(repr(coordinates)) not permited; try :distance or :geographic")
    end
end

