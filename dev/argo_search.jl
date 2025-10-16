# Show Argo profiles within 200 km of Sable Island in last year
using OceanAnalysis, CSV, Dates, DataFrames, Plots
# Get the index
index_file = get_argo_index("~/data/argo")
index_all = read_argo_index(index_file) # 3.2e6 profiles
# Set time subset
today = now(UTC)
start = today - Dates.Year(1)
recent = start .< index_all.time .< today
# Set distance subset
SI_lon = -59.915
SI_lat = 43.934
radius = 200.0 # km
distance = map(i -> geod_distance(SI_lon, SI_lat,
        index_all.longitude[i], index_all.latitude[i]),
    1:nrow(index_all))
near = distance .< radius
# Filter by both time and distance
index = index_all[recent.&near, :]
# Extend region of map to show geographic context
aspect_ratio = 1.0 / cos(SI_lat * pi / 180.0)
scale = radius / 111.
scatter(index.longitude, index.latitude,
    xlims=SI_lon .+ scale .* (-1.2, 1.2) .* aspect_ratio,
    ylims=SI_lat .+ scale .* (-1.2, 1.2),
    aspect_ratio=aspect_ratio,
    tickdirection=:out, framestyle=:box, dpi=200, legend=false)
plot_coastline!(coastline())
float_IDs = replace.(index.file, r".*/(.*)_.*" => s"\1") |> unique
title!("$(length(index.file)) profiles of $(length(float_IDs)) floats", titlefontsize=9)
scale_bar(100)
savefig("argo_search.png")
