# Show Argo profiles within 200 km of Sable Island in last 5 years
using OceanAnalysis, CSV, DataFrames, Dates, Printf
using GLMakie # or CairoMakie
radius = 200 # km
years = 5 # years
using GLMakie # or CairoMakie
# Get the index
index_file = get_argo_index("~/data/argo")
index_all = read_argo_index(index_file)
# Set time subset
today = now(UTC)
start = today - Dates.Year(years)
recent = start .< index_all.time .< today
# Set distance subset
lon0 = -59.915
lat0 = 43.934
radius = 200.0 # km
distance = map(i -> geod_distance(lon0, lat0,
        index_all.longitude[i], index_all.latitude[i]),
    1:nrow(index_all))
near = distance .< radius
# Filter by both time and distance
index = index_all[recent.&near, :]

# Extend region of map to show geographic context
t = "$(length(index.file)) profiles within $radius km of Sable Island in $years years"
fig = plot_coastline(coastline(), title=t,
    limits=[lon0 - 3; lon0 + 3; lat0 - 3; lat0 + 3])
scatter!(index.longitude, index.latitude)

save("argo_search.png", fig, px_per_unit=2)
