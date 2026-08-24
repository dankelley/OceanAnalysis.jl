using OceanAnalysis, Plots, CSV, DataFrames
search = "Bedford" # full name is "Bedford Institute"
name, csv = get_tide_gauge_file(search)
data = CSV.read(csv, DataFrame)
xlim = extrema(data.time)
plot(data.time, data.value, xlim=xlim, label=false,
    framestyle=:box, tickdirection=:out, ylab="Elevation [m]",
    title=name, labelfontsize=8, titlefontsize=8)
savefig("tide_gauge_timeseries.png")

