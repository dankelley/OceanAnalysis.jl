using HTTP, JSON3
using DataFrames, CSV
using Dates
using Printf
using Downloads

"""
    get_tide_gauge_index(name=:all)

Get an index of tide-gauge data available on the Canadian
Hydrographic Service (CHS) website.

# Arguments

- `search` a string to be used for a search on station name. If this matches
    to several stations, the result will be a data frame with one row per match.

# Return

This returns a DataFrame with one row per match in the database.

# References

1. The API used by the CHS server is described at
https://api.iwls-sine.azure.cloud-nuage.dfo-mpo.gc.ca/swagger-ui/index.html

# Examples

```julia
# Show Nova Scotian stations, in red if permanent
using OceanAnalysis, Plots
i = get_tide_gauge_index(:all);
scatter(i.longitude, i.latitude,
    aspect_ratio=1.0 / cos(48.0 * pi / 180),
    framestyle=:box, tickdirection=:out, label=false, ms=0,
    xlim=(-67, -59), ylim=(43.3, 47.2))
plot_coastline!(coastline(:global_fine), fillcolor=:gray95)
scatter!(i.longitude, i.latitude, color=:blue, ms=2,
    markerstrokewidth=0.2)
look = i.type .== "PERMANENT"
scatter!(i.longitude[look], i.latitude[look],
    color=:red, ms=4, markerstrokewidth=0.2)
```
"""
function get_tide_gauge_index(search=:all)
    url = "https://api-iwls.dfo-mpo.gc.ca/api/v1/stations"
    response = HTTP.get(url)
    r = JSON3.read(response.body)
    n = length(r)
    id = Vector{String}(undef, n)
    official_name = Vector{String}(undef, n)
    code = Vector{String}(undef, n)
    lon = Vector{Float64}(undef, n)
    lat = Vector{Float64}(undef, n)
    type = Vector{String}(undef, n)
    for i in eachindex(r)
        ri = r[i]
        official_name[i] = ri["officialName"]
        code[i] = ri["code"]
        lon[i] = ri["longitude"]
        lat[i] = ri["latitude"]
        id[i] = ri["id"]
        type[i] = ri["type"]
    end
    if search == :all
        return DataFrame(id=id, code=code, name=official_name, longitude=lon, latitude=lat, type=type)
    else
        j = findall(occursin.(search, official_name))
        if length(j) < 1
            error("No stations match string '$search'")
        end
        return DataFrame(id=id[j], code=code[j], name=official_name[j], longitude=lon[j], latitude=lat[j], type=type[j])
    end
end
export get_tide_gauge_index



"""
    get_tide_gauge_file(name; times=:default, variable=:wlo, resolution=3)

Get a tide-gauge datafile from the Canadian Hydrographic Service (CHS).

This is a preliminary function, not well-tested as of initial coding
in early August 2026. Changes to the interface are not unlikely.

# Arguments

- `name` a String indicating the name (or a fragment of the name) of the gauge
  for which data are sought.

# Keywords

- `times` an indication of the start and end times for which data are sought.
  This may be either a Tuple holding 2 DateTime values or the symbol
  `:default` (in which case the interval ranges from 7 days ago to the
  present time).

- `variable` a symbol indicating what data are sought, with `:wlo` for
  water-level observations of `:wlp` for water-level predictions.

- `resolution` an integer giving the number of minutes data samples.
  The CHS server may report errors if an attempt is made to download
  long records at high resolution.

  # Examples
```julia
# Show past week of sealevel in Bedford Basin, Nova Scotia
using OceanAnalysis, Plots, CSV, DataFrames
search = "Bedford"
name, csv = get_tide_gauge_file(search)
data = CSV.read(csv, DataFrame)
plot(data.time, data.value, label=false,
    framestyle=:box, tickdirection=:out, ylab="Elevation [m]",
    title=name, labelfontsize=8, titlefontsize=8)
```

# References

1. The API used by the CHS server is described at
https://api.iwls-sine.azure.cloud-nuage.dfo-mpo.gc.ca/swagger-ui/index.html

"""
function get_tide_gauge_file(search; times=:default, variable=:wlo, resolution=3)
    isa(variable, Symbol) || error("variable must be a symbol, e.g. :wlo or :wlp")
    variable in (:wlo, :wlp) || error("variable must be :wlo or :wlp, but it is $variable")
    # FIXME: if add NOAA, then resolution must be in (1,6,60)
    resolution in (1, 3, 5, 15, 60) || error("resolution must be 1, 3, 5, 15 or 60, but it is $resolution")
    rdict = Dict(1 => "ONE_MINUTE", 2 => "TWO_MINUTES", 3 => "THREE_MINUTES", 5 => "FIVE_MINUTES", 15 => "FIFTEEN_MINUTES", 60 => "SIXTY_MINUTES")
    resolution = rdict[resolution]
    if times == :default
        n = now()
        times = (n - Day(7), n)
    end
    if length(times) != 2
        error("length of times (", length(times), ") is not 2, as is required")
    end
    i = get_tide_gauge_index(search)
    nr = size(i, 1)
    if nr > 1
        error("$nr gauges match this name; try using name=:default to get a listing")
    end
    i = i[1, :]
    fmt = "yyyy-mm-ddTHH%3AMM%3A00Z"
    url = @sprintf("https://api-iwls.dfo-mpo.gc.ca/api/v1/stations/%s/data?time-series-code=%s&from=%s&to=%s&resolution=%s", i.id, String(variable), Dates.format(times[1], fmt), Dates.format(times[2], fmt), resolution)
    filename = "tide_gauge_" * i.code * "_" * Dates.format(times[1], "yyyymmddTHHMM") * "_" * Dates.format(times[2], "yyyymmddTHHMM") * "_" * String(variable) * "_" * resolution * ".csv"
    # Save JSON file to a temporary location, then decode it
    # and save time,value to a CSV file.
    data = mktemp() do tmp_path, tmp_io
        close(tmp_io)
        Downloads.download(url, tmp_path)
        open(tmp_path) do io
            return JSON3.read(io)
        end
    end
    n = length(data)
    values = Vector{Float64}(undef, n)
    times = Vector{DateTime}(undef, n)
    for i in eachindex(data)
        times[i] = DateTime(data[i]["eventDate"], "yyyy-mm-ddTHH:MM:SSZ")
        values[i] = data[i]["value"]
    end
    df = DataFrame(time=times, value=values)
    println(first(df, 3))
    CSV.write(filename, df)
    (station_name=i.name, file=filename)
end
export get_tide_gauge_file
