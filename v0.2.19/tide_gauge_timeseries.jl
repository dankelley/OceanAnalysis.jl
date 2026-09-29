using OceanAnalysis, CSV, DataFrames
using GLMakie # or CairoMakie

search = "Bedford" # full name is "Bedford Institute"
name, csv = get_tide_gauge_file(search)
data = CSV.read(csv, DataFrame)

fig = Figure()
ax = Axis(fig[1, 1], ylabel="Elevation [m]", title="Sea Level at $name")
lines!(data.time, data.value)

save("tide_gauge_timeseries.png", fig, px_per_unit=5)

