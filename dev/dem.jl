# Differentiated view of Halifax's Citadel Fort
using OceanAnalysis
using GLMakie # or CairoMakie

dem_id = "1044600063500_201901_DEM"
file = expanduser("~/data/lidar/$dem_id/$dem_id.tif")
if isfile(file)
    dem = read_dem(file)
    lims = (-63.587, -63.575, 44.6426, 44.655)
    dem = subset_dem(dem, lonlim=lims[1:2], latlim=lims[3:4])
    fig = plot_dem(dem, coordinates=:geographic)
    save("dem_1.png", fig, px_per_unit=4)
    dem_slope = differentiate_dem(dem)
    fig = plot_dem(dem_slope, coordinates=:geographic, colorrange=(-0.5, 0.5))
    save("dem_2.png", fig, px_per_unit=4)
end

