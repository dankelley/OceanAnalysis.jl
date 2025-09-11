using OceanAnalysis, CSV, Dates, DataFrames, Plots
# Get the index
index_file = get_argo_index("~/data/argo")
index = read_argo_index(index_file)
# Select profiles going back 1 month
today = now(UTC)
start = today - Dates.Month(1)
look = start .< index.time .< today
lon = index.longitude[look]
lat = index.latitude[look]
# Plot a map
scatter(lon, lat, xlims=(-180, 180), ylims=(-90, 90),
    aspect_ratio=1.0 / cos(45 * pi / 180.0),
    markersize=1, markerstrokecolor=:blue, color=:blue,
    framestyle=:box, dpi=150, legend=false,
    title="Argo profiles during $(Day(today-start))")
cl_file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "coastline.csv.gz")
cl = CSV.read(cl_file, DataFrame, header=1)
plot!(cl.longitude, cl.latitude, seriestype=:shape, color=:bisque3)
savefig("argo_index.png")
