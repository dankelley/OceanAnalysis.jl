using OceanAnalysis, CSV, DataFrames
using GLMakie # or CairoMakie

search = "Bedford" # full name is "Bedford Institute"
csv = get_tide_gauge_file(search)
data = CSV.read(csv, DataFrame)

fig = lines(data.time, data.value; axis=(ylabel="Elevation [m]",))

save("tide_gauge_timeseries.png", fig, px_per_unit=2)

