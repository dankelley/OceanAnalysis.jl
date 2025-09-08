# Map Argo profile locations since a month ago
using Dates, CSV, DataFrames, Plots, OceanAnalysis
# Download and read the profile index
download_argo_index("~/data/argo/ss")
df = read_argo_index("~/data/argo/ss/ar_index_global_prof.txt.gz")
# Isolate profiles made since a month ago
t1 = floor(now(UTC), Dates.Day)
t0 = t1 - Dates.Month(1)
look = (t0 .<= df.time) .* (df.time .< t1)
df = df[look, :]
# Plot profile locations in world domain
d0f = Dates.format(t0, "yyyy-mm-d")
d1f = Dates.format(t1, "yyyy-mm-d")
title = "$(nrow(df)) Argo profiles from $d0f to $d1f"
scatter(df.longitude, df.latitude,
    markersize=1.0, color=:blue2, markerstrokecolor=:blue2,
    xlimits=(-180, 180), ylimits=(-90, 90), aspect_ratio=:equal,
    framestyle=:box, dpi=150, legend=false,
    title=title, titlefontsize=9)
# Add coastline for reference
cl_file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "coastline.csv.gz")
cl = CSV.read(cl_file, DataFrame, header=1)
plot!(cl.longitude, cl.latitude, color=:sienna4)
savefig("argo_map.png")
