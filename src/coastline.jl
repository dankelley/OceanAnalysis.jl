"""
    coastline(symbol::Symbol=:world)

Access a built-in coastline dataset. The only valid choices for `name` are
`:world_coarse` and `:world_fine`.  These are handled by reading the built-in
datasets `data/coastline_coarse.csv.gz` and datasets
`data/coastline_fine.csv.gz`, respectively.

# Examples

```juliadoc
# Plot earth with the coarse dataset and Nova Scotia with the fine dataset
using OceanAnalysis, Plots
clc = coastline(:global_coarse);
clf = coastline(:global_fine);
# World view
p1 = plot(clc.data.longitude, clc.data.latitude,
    xlim=(-180, 180), ylim=(-90, 90),
    aspect_ratio=1.0,
    seriestype=:shape, color=:bisque3, legend=false, framestyle=:box)
# Nova Scotia view, with aspect_ratio set for the middle latitude
p2 = plot(clf.data.longitude, clf.data.latitude,
    xlim=(-68, -59), ylim=(42, 48),
    aspect_ratio=1.0 / cos(45.0 * pi / 180),
    seriestype=:shape, color=:bisque3, legend=false, framestyle=:box)
l = @layout [a{0.66w} b{0.33w}]
plot(p1, p2, layout=l)
savefig("maps.png")
```
"""
function coastline(name::Symbol=:global_fine)
    #println("coastline(name) BEGIN")
    dir = dirname(dirname(pathof(OceanAnalysis)))
    if name == :global_fine
        rval = coastline(joinpath(dir, "data", "coastline_fine.csv.gz"), 1)
        rval.metadata["name"] = name
    elseif name == :global_coarse
        rval = coastline(joinpath(dir, "data", "coastline_coarse.csv.gz"), 1)
        rval.metadata["name"] = name
    else
        error("    the only choices for 'name' are :global_coarse and :global_fine, but :", name, " was given")
    end
    rval
end

"""
    coastline(filename::String, header::Integer=0)

Return a coastline stored in the named CSV file (in either text or gzipped form).

The work is done by passing `filename` and `header` to `CSV.read()`. The file
must have 1 or more header lines, the last of which must contain column names
`longitude` and `latitude`. NaN values will be taken to indicate breaks between
segments that trace continents, nations, etc.

# Examples

```juliadoc
using OceanAnalysis, Plots
dir = dirname(dirname(pathof(OceanAnalysis)));
file = joinpath(dir, "data", "coastline_fine.csv.gz");
cl = coastline(file, 1);
plot(cl.data.longitude, cl.data.latitude, aspect_ratio=1.0,
    seriestype=:shape, color=:lightgray, legend=false,
    framestyle=:box, xlim=(-180, 180), ylim=(-90, 90))
```
"""
function coastline(filename::String, header::Integer=1)
    !ismissing(filename) || error("must supply 'filename', the path to a CSV file")
    header > 0 || error("'header' must be a non-negative integer")
    metadata = Dict()
    metadata["filename"] = expanduser(filename)
    if header == 0
        data = CSV.read(filename, DataFrame, header=header)
    else
        data = CSV.read(filename, DataFrame, header=header)
    end
    Coastline(metadata, data)
end

"""
    coastline(longitude::Vector{Real}, latitude::Vector{Real})

Create a Coastline from longitude and latitude values.  Use NaN values
for each of these to indicate breaks in the coastline from continent
to continent, nation to nation, etc.

# Examples
```juliadoc
using OceanAnalysis, CSV, Plots, DataFrames
dir = dirname(dirname(pathof(OceanAnalysis)));
file = joinpath(dir, "data", "coastline_fine.csv.gz");
data = CSV.read(file, DataFrame, header=1);
cl = coastline(data.longitude, data.latitude);
plot(cl.data.longitude, cl.data.latitude, aspect_ratio=1.0,
    seriestype=:shape, color=:lightgray, legend=false,
    framestyle=:box, xlim=(-180, 180), ylim=(-90, 90))
```
"""
function coastline(longitude::Vector{Float64}, latitude::Vector{Float64})
    metadata = Dict()
    metadata["source"] = "(user-supplied vectors of longitude and latitude)"
    data = DataFrame(longitude=longitude, latitude=latitude)
    Coastline(metadata, data)
end

"""
    plot_coastline(coastline::Coastline, ...)

FIXME: this seems to work, but I need to explore more before writing documentation.
Is there any benefit over the user just using [`plot`](@ref) directly?
"""
function plot_coastline(coastline::Coastline; clongitude::Real=0.0, clatitude::Real=0.0, span::Real=90.0,
    seriestype=:shape, legend=false, color=:tan) #, kwargs...)
    #println("plot_coastline() BEGIN")
    #println("kwargs...: ", kwargs...)
    #println("keys((; kwargs...)): ", keys((; kwargs...)))
    # NB. we can see if 'legend' is in the kwargs by using
    #     if "legend" in keys((; kwargs...))
    # and I thought I would need to do that, but testing shows that if the
    # user gives say 'legend' then it does not appear in kwargs, so no
    # need for this complication.
    aspect_ratio = 1.0 / cos(clatitude * pi / 180.0)
    #println("lon: ", first(coastline.data.longitude, 3))
    #println("lat: ", first(coastline.data.latitude, 3))
    plot(coastline.data.longitude, coastline.data.latitude,
        xlims=(clongitude - 2.0 * span * aspect_ratio, clongitude + 2.0 * span * aspect_ratio),
        ylims=(clatitude - span, clatitude + span),
        aspect_ratio=aspect_ratio,
        legend=legend,
        seriestype=seriestype, color=color, framestyle=:box)
    #kwargs...)
end

"""
    plot_coastline!(coastline::Coastline, ...)

FIXME: this seems to work, but I need to explore more before writing documentation.
Is there any benefit over the user just using `plot!()` directly?
"""
function plot_coastline!(coastline::Coastline; legend=false, seriestype=:shape, color=:tan)#, kwargs...)
    #println("plot_coastline!() BEGIN")
    #println("kwargs...: ", kwargs...)
    #println("keys((; kwargs...)): ", keys((; kwargs...)))
    plot!(coastline.data.longitude, coastline.data.latitude,
        xlims=xlims(), ylims=ylims(),
        legend=legend,
        seriestype=seriestype, color=color, framestyle=:box)
    #kwargs...)
end

