using OceanAnalysis, Plots

file = "/Users/kelley/Downloads/1044600063500_201901_DEM/1044600063500_201901_DEM.tif"

if isfile(file)
    dem_all = read_dem(file)
    # Focus near the Citadel fort
    dem = subset_dem(dem_all, lonlim=(-63.589, -63.572), latlim=(44.6426, 44.655))
    middle_lat = dem["latitude"][div(end + 1, 2)]
    aspect_ratio = 1.0 / cos(middle_lat * pi / 180.0)
    # Heatmap of elevation
    p1 = heatmap(dem["longitude"], dem["latitude"], dem.data,
        color=:inferno, aspect_ratio=aspect_ratio,
        framestyle=:box, tickdirection=:out)
    savefig("dem_1.png")
    # Heatmap of gradient of elevation with respect to northerly distance
    z = -diff(dem.data, dims=1) / dem["dy"]
    z = [zeros(1, size(dem.data, 2)); z]
    heatmap(dem["longitude"], dem["latitude"], z,
        color=:inferno, aspect_ratio=aspect_ratio,
        framestyle=:box, tickdirection=:out, clim=(-0.5, 0.5))
    savefig("dem_2.png")
end

