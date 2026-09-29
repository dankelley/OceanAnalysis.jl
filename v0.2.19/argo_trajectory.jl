# Plot a float trajectory with colour for sequence number
using OceanAnalysis, Printf, Statistics
using GLMakie # CairoMakie
ID = r"D4902911" # focus on this ID
index_file = get_argo_index("~/data/argo");
index_all = read_argo_index(index_file) # 3.2e6 profiles
index = index_all[occursin.(ID, index_all.file), :]
sort!(index, :time) # this lets us join dots in time order
lon, lat = index.longitude, index.latitude
lonr = extrema(lon)
latr = extrema(lat)
fig = plot_coastline(coastline(),
    scalebar=(distance=500, x=:right, y=:top),
    limits=[lonr[1] - 2; lonr[2] + 2; latr[1] - 2; latr[2] + 4])
scatterlines!(lon, lat)

save("argo_trajectory.png", fig, px_per_unit=2)
