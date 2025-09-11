# %%
using OceanAnalysis, CSV, DataFrames, PolygonOps, Plots
index_file = get_argo_index("~/data/argo")
index = read_argo_index(index_file)
lon = index.longitude
lat = index.latitude
time = index.time
n = length(lon)

# Find points inside Laurentian Channel (lc)
# %%
lc = [
    (-57.545, 44.609),
    (-57.544, 45.335),
    (-58.302, 45.899),
    (-58.884, 45.990),
    (-59.269, 46.535),
    (-60.297, 47.454),
    (-60.796, 48.002),
    (-62.197, 48.481),
    (-63.044, 48.822),
    (-61.421, 48.994),
    (-60.709, 48.969),
    (-60.367, 49.252),
    (-59.827, 49.375),
    (-59.725, 48.830),
    (-59.670, 47.964),
    (-59.179, 47.338),
    (-58.028, 47.103),
    (-57.240, 46.250),
    (-56.500, 45.507),
    (-56.095, 45.061),
    (-57.545, 44.609)
]

# %%
inside = filter(i -> inpolygon((lon[i], lat[i]), lc) == 1, 1:n)
N = length(inside)
Lon = lon[inside]
Lat = lat[inside]
Time = time[inside]

# %%
p1 = scatter(Lon, Lat, xlims=(-65, -55), ylims=(43, 50),
    aspect_ratio=1.0 / cos(45 * pi / 180.0),
    markersize=1, framestyle=:box, dpi=150, legend=false)
cl_file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "coastline_fine.csv.gz")
cl = CSV.read(cl_file, DataFrame, header=1)
plot!(cl.longitude, cl.latitude, color=:sienna4)
lcdf = DataFrame(lc)
plot!(lcdf[:, 1], lcdf[:, 2], color=:red)


# %%
p2 = scatter(Time, Lat, margin_top=1,
    ylabel="Latitude [°N]",
    guidefont=font(8), markersize=1, framestyle=:box, dpi=150, legend=false)

# %%
l = @layout [a{0.8h}; b]
plot(p1, p2, layout=l)
savefig("argo_index.png")
