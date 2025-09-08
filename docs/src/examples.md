# Examples

## CTD diagnostic plots

The following shows how to read a built-in CTD file, and plot some hydrographic
diagrams.

```julia
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "ctd.cnv")
ctd = read_ctd_cnv(filename)
p1 = plot_profile(ctd, "CT")
p2 = plot_profile(ctd, "SA")
p3 = plot_profile(ctd, "sigma0")
p4 = plot_TS(ctd)
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 800), margin=0.25cm,
    dpi=200)
savefig("ctd_diagram.png")
```
![CTD diagram](ctd_diagram.png)

## Argo map

The following shows how to map Argo profile locations since a month ago.

```julia
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
    framestyle=:box, dpi=100, legend=false,
    title=title, titlefontsize=9)
# Add coastline for reference
coastline_file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "coastline.csv.gz")
coastline = CSV.read(coastline_file, DataFrame, header=1)
plot!(coastline.longitude, coastline.latitude, color=:sienna4)
savefig("argo_map.png")
```
![Argo map](argo_map.png)

