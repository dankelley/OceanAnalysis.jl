# Examples

## Satellite view of SST

The AMSR satellite provides several data streams, including sea-surface
temperature, which may be plotted as follows.

```julia
# North Atlantic Sea Surface Temperature
using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc"
a = read_amsr(f, "SST");
plot_amsr(a, xlims=(290.0, 360.0), ylims=(20.0, 60.0), color=:turbo,
    levels=0.0:2.5:30.0, clim=(0, 30))
!savefig("amsr.png")
```

![AMSR-derived sea-surface temperature](amsr.png)

## Topography

The following downloads topographic data for a domain including southern
Nova Scotia, and plots in three plot styles.

```julia
using OceanAnalysis, Plots, TiffImages
topo_file = get_topography_file(-67, -63, 43, 46, resolution=1)
topo = read_topography(topo_file);
p1 = plot_topography(topo, domain=:both);
p2 = plot_topography(topo, domain=:sea);
p3 = plot_topography(topo, domain=:land);
plot(p1, p2, p3, layout=(1, 3), size=(800, 200), dpi=300)
!savefig("topography.png")
```

![Topography diagram](topography.png)

## CTD profile diagnostic plot

The following shows how to read a built-in CTD file, and plot some hydrographic
diagrams.

```julia
# Read and plot a built-in CTD file
using OceanAnalysis, Plots, Measures, Dates
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "ctd.cnv")
ctd = read_ctd_cnv(filename)
p1 = plot_profile(ctd, which="CT");
p2 = plot_profile(ctd, which="SA");
p3 = plot_profile(ctd, which="sigma0");
p4 = plot_TS(ctd);
title = "CTD observations at " *
        "$(round(ctd.metadata["latitude"],digits=3))N and " *
        "$(round(ctd.metadata["longitude"],digits=3))E" *
        " on $(Dates.format(ctd.metadata["time"], "yyyy-mm-dd"))"
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 600), margin=0.25cm,
    dpi=200, plot_title=title, plot_titlefontsize=11)
#savefig("ctd_diagram.png")
```

![CTD diagram](ctd_diagram.png)

## Argo subset and map

The following shows how to map Argo profile locations made within 500 km
of Sable Island, within the past 365 days.

```julia
# Map argo locations in last year, with red dots within 500km of Sable Island
using OceanAnalysis, CSV, Dates, DataFrames, Plots
# Get the index
index_file = get_argo_index("~/data/argo")
index = read_argo_index(index_file) # 3.2e6 profiles
# Select profiles made within the past 365 days
today = now(UTC)
start = today - Dates.Year(1)
index_recent = index[start.<index.time.<today, :] # 1.7e4 profiles
# Isolate profiles made within 500 km of Sable Island
SI_lon = -59.915
SI_lat = 43.934
distance = map(i -> geod_distance(SI_lon, SI_lat,
        index_recent.longitude[i], index_recent.latitude[i]),
    1:nrow(index_recent))
index_near = index_recent[distance.<500, :]
# plot results on a map
scatter(index_recent.longitude, index_recent.latitude,
    xlims=SI_lon .+ (-15, 15),
    ylims=SI_lat .+ (-10, 10),
    aspect_ratio=1.0 / cos(SI_lat * pi / 180.0),
    markersize=1, markerstrokecolor=:blue, color=:blue,
    tickdirection=:out,
    framestyle=:box, dpi=200, legend=false)
scatter!(index_near.longitude, index_near.latitude, markersize=1.5,
    markerstrokecolor=:red, color=:red)
# add a coastline for reference
plot_coastline!(coastline(:global_fine))
#savefig("argo_map.png")
```

![Argo map](argo_map.png)

## Argo profile diagnostic plot

The following shows how to display some useful diagnostic plots for a single
Argo profile.

```julia
# Read and plot a built-in Argo file
using OceanAnalysis, Plots, Measures, Dates
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
a = read_argo(filename)
p1 = plot_profile(a, which="CT");
p2 = plot_profile(a, which="SA");
p3 = plot_profile(a, which="sigma0");
p4 = plot_TS(a);
title = "CTD observations at " *
        "$(round(a.metadata["latitude"],digits=3))N and " *
        "$(round(a.metadata["longitude"],digits=3))E" *
        " on $(Dates.format(a.metadata["time"], "yyyy-mm-dd"))"
plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 600), margin=0.25cm,
    dpi=200, plot_title=title, plot_titlefontsize=11)
#savefig("argo_profile.png")
```

![Argo profile](argo_profile.png)
