"""
    plot_stations(longitude::Vector{Float64}, latitude::Vector{Float64};
        draw_coastline::Bool=true, debug::Int64=0, kwargs...)

Plot station locations (or similar data) on a map.

The locations are plotted with `scatter`, with aspect ratio computed using
the midpoint between the extrema of `latitude`. If `show_coastline` is true,
then [`plot_coastline`](@ref) is called to draw the land.

# Arguments

- `longitude` a vector of longitudes, in the -180 to 180 degree frame.

- `latitude` a vector of latitudes, in the -90 to 90 degree frame.

# Keywords

- `draw_coastline`: a Bool value indicating whether to plot the coastline, using [`plot_coastline`](@ref).

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed down to lower-level plotting functions. For example, `size` controls the size of the plot, `xlim` and `ylim` control the viewing window, `color` controls the land colour, and `markercolor` controls the station-location colour.

# Examples

```julia
using OceanAnalysis, Plots
# Twenty fake stations between Halifax and Sable Island
lon = collect(range(-59.91, -63.53, length=20))
lat = collect(range(43.93, 44.59, length=20))
plot_stations(lon, lat, xlim=(-65.0, -59.0), ylim=(43.0, 46.0))
```
"""
function plot_stations(longitude::Vector{Float64}, latitude::Vector{Float64};
    draw_coastline::Bool=true, debug::Int64=0, kwargs...)
    oad(debug, "plot_stations(longitude, latitude, ...)")
    if haskey(kwargs, :ylim)
        kw = (; kwargs...)
        mid_latitude = 0.5 * sum(kw[:ylim])
    else
        mid_latitude = 0.5 * sum(extrema(filter(!isnan, latitude)))
    end
    oad(debug, "  mid_latitude=$mid_latitude")
    aspect_ratio = 1.0 / cos(mid_latitude * pi / 180.0)
    oad(debug, "  aspect_ratio=$aspect_ratio")
    pl = scatter(longitude, latitude;
        aspect_ratio=aspect_ratio, tickdirection=:out, framestyle=:box, legend=false,
        markershape=:xcross, markercolor=:black, markersize=3,
        kwargs...)
    if draw_coastline
        plot_coastline!(coastline(); kwargs...)
    end
    oad(debug, "END plot_stations()")
    pl
end

"""
    plot_stations(section::Section; draw_coastline::Bool=true, debug::Int64=0, kwargs...)

Plot section station locations on a map.

The locations are plotted with `scatter`, with aspect ratio computed using
the midpoint between the extrema of `latitude`. If `show_coastline` is true,
then [`plot_coastline`](@ref) is called to draw the land.

# Arguments

- `section` a [`Section`](@ref).

# Keywords

- `draw_coastline`: a Bool value indicating whether to plot the coastline, using [`plot_coastline`](@ref).

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed down to lower-level plotting functions. For example, `size` controls the size of the plot, `xlim` and `ylim` control the viewing window, `color` controls the land colour, and `markercolor` controls the station-location colour.

# Examples

```julia
using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
plot_stations(s, xlim=(-80,0), ylim=(20,50))
```
"""
function plot_stations(section::Section; draw_coastline::Bool=true, debug::Int64=0, kwargs...)
    plot_stations(section["longitude"], section["latitude"]; draw_coastline=draw_coastline, debug=debug, kwargs...)
end
