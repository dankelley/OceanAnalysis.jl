using OceanAnalysis
using GLMakie # or CairoMakie

file = "/Users/kelley/data/lidar/1044600063500_201901_DEM/1044600063500_201901_DEM.tif"

if isfile(file)
    dem_all = read_dem(file)
    # Focus near the Citadel fort
    lims = (-63.589, -63.572, 44.6426, 44.655)
    dem = subset_dem(dem_all, lonlim=lims[1:2], latlim=lims[3:4])
    fig1 = plot_dem(dem)
    save("dem_1.png", fig1, px_per_unit=2)
    fig2 = plot_dem(dem, coordinates=:geographic)
    save("dem_2.png", fig2, px_per_unit=2)
end

