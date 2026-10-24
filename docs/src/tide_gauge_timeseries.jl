using OceanAnalysis, CSV, DataFrames
using GLMakie # or CairoMakie

search = "Bedford" # full name is "Bedford Institute"
name, csv = get_tide_gauge_file(search)
data = CSV.read(csv, DataFrame)

fig = lines(data.time, data.value;
    axis=(ylabel="Elevation [m]", title="Sea Level at $name"))

save("tide_gauge_timeseries.png", fig, px_per_unit=2)

