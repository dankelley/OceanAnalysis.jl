# %%
using OceanAnalysis, CSV, DataFrames, Plots, PolygonOps, Dates
include("regionNovaScotia.jl"); # defines scotian_shelf_polygon
index_file = "~/data/argo/ss/ar_index_global_prof.txt.gz"

# %%
if !@isdefined index
    println("Reading 'index' from ", index_file)
    index = read_argo_index(index_file) # takes 4.8s
else
    println("Using 'index' cached from earlier in this session")
end

# %%
lon = index.longitude
lat = index.latitude
time = index.time
n = length(lon)

# %%
# Find points inside region (takes 0.3s)
inside = filter(i -> inpolygon((lon[i], lat[i]), scotian_shelf_polygon) == 1, 1:n);
time_start, time_end = extrema(time[inside])
nn = length(inside)

# %%
title = "$nn selected profiles from " * Dates.format(time_start, "yyyy-mm-dd") * " to " * Dates.format(time_end, "yyyy-mm-dd")
asp = 1 / cos(45.0 * pi / 180)
plot(lon, lat, xlims=(-70, -50), ylims=(38, 48), seriestype=:scatter, color=:lightgray, markerstrokecolor=:lightgray, markersize=1, legend=false, aspect_ratio=asp, dpi=200, title=title, titlefontsize=9, framestyle=:box)
scatter!(lon[inside], lat[inside], markersize=1, color=:black)
coastline_file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "coastline_fine.csv.gz");
coastline = CSV.read(coastline_file, DataFrame, header=1)
plot!(coastline.longitude, coastline.latitude, color=:sienna)
savefig("argo_scotian_shelf.png")
