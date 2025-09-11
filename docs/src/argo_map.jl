# Map Argo profile locations since a month ago
using Dates, CSV, DataFrames, Plots, OceanAnalysis
# Download and read the profile index
index_file = get_argo_index("~/data/argo/")
index = read_argo_index(index_file)
# Isolate profiles made since a month ago
t1 = floor(now(UTC), Dates.Day)
t0 = t1 - Dates.Month(1)
look = t0 .<= index.time .< t1
index = index[look, :]
# Plot profile locations in world domain
t0f = Dates.format(t0, "yyyy-mm-d")
t1f = Dates.format(t1, "yyyy-mm-d")
title = "$(nrow(index)) Argo profiles from $t0f to $t1f"
scatter(index.longitude, index.latitude,
    markersize=1.0, color=:blue2, markerstrokecolor=:blue2,
    xlimits=(-180, 180), ylimits=(-90, 90), aspect_ratio=:equal,
    framestyle=:box, dpi=150, legend=false,
    title=title, titlefontsize=9)
# Add land for reference
cl_file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "coastline.csv.gz")
cl = CSV.read(cl_file, DataFrame, header=1)
plot!(cl.longitude, cl.latitude, seriestype=:shape, color=:bisque3)
savefig("argo_map.png")
