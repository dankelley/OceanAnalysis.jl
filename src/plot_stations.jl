# There is really no need for this function. Users can easily
# plot a coastline and then add points with scatter!().
#
#<disabled> """
#<disabled>     plot_stations(longitude::Vector{Float64}, latitude::Vector{Float64};
#<disabled>         draw_coastline::Bool=true, debug::Integer=0, kwargs...)
#<disabled> 
#<disabled> Plot station locations (or similar data) on a map.
#<disabled> 
#<disabled> The locations are plotted with `scatter`, with aspect ratio computed using
#<disabled> the midpoint between the extrema of `latitude`. If `show_coastline` is true,
#<disabled> then [`plot_coastline`](@ref) is called to draw the land.
#<disabled> 
#<disabled> # Arguments
#<disabled> 
#<disabled> - `longitude` a vector of longitudes, in the -180 to 180 degree frame.
#<disabled> 
#<disabled> - `latitude` a vector of latitudes, in the -90 to 90 degree frame.
#<disabled> 
#<disabled> # Keywords
#<disabled> 
#<disabled> - `draw_coastline`: a Bool value indicating whether to plot the coastline,
#<disabled>    using [`plot_coastline`](@ref).
#<disabled> 
#<disabled> - `debug`: an optional value that, if it exceeds 0, indicates that debugging
#<disabled>   output should be printed during processing.
#<disabled> 
#<disabled> - `kwargs`: optional items, passed down to lower-level plotting functions. For
#<disabled>   example, `size` controls the size of the plot, `xlim` and `ylim` control the
#<disabled>   viewing window, `color` controls the land colour, and `markercolor` controls
#<disabled>   the station-location colour.
#<disabled> 
#<disabled> # Examples
#<disabled> 
#<disabled> ```julia
#<disabled> using OceanAnalysis, Plots
#<disabled> # Twenty fake stations between Halifax and Sable Island
#<disabled> lon = collect(range(-59.91, -63.53, length=20))
#<disabled> lat = collect(range(43.93, 44.59, length=20))
#<disabled> plot_stations(lon, lat, xlim=(-65.0, -59.0), ylim=(43.0, 46.0))
#<disabled> ```
#<disabled> """
#<disabled> function plot_stations(longitude::Vector{Float64}, latitude::Vector{Float64};
#<disabled>     draw_coastline::Bool=true, debug::Integer=0, kwargs...)
#<disabled>     error("plot_stations() disabled, pending convertion from Plots to Makie")
#<disabled>     #<disabled>    oad(debug, "plot_stations(longitude, latitude, ...)")
#<disabled>     #<disabled>    if haskey(kwargs, :ylim)
#<disabled>     #<disabled>        kw = (; kwargs...)
#<disabled>     #<disabled>        mid_latitude = 0.5 * sum(kw[:ylim])
#<disabled>     #<disabled>    else
#<disabled>     #<disabled>        mid_latitude = 0.5 * sum(extrema(filter(!isnan, latitude)))
#<disabled>     #<disabled>    end
#<disabled>     #<disabled>    oad(debug, "  mid_latitude=$mid_latitude")
#<disabled>     #<disabled>    aspect_ratio = 1.0 / cos(mid_latitude * pi / 180.0)
#<disabled>     #<disabled>    oad(debug, "  aspect_ratio=$aspect_ratio")
#<disabled>     #<disabled>    pl = scatter(longitude, latitude;
#<disabled>     #<disabled>        aspect_ratio=aspect_ratio, tickdirection=:out, framestyle=:box, legend=false,
#<disabled>     #<disabled>        markershape=:xcross, markercolor=:black, markersize=3,
#<disabled>     #<disabled>        kwargs...)
#<disabled>     #<disabled>    if draw_coastline
#<disabled>     #<disabled>        plot_coastline!(coastline(); kwargs...)
#<disabled>     #<disabled>    end
#<disabled>     #<disabled>    oad(debug, "END plot_stations()")
#<disabled>     #<disabled>    pl
#<disabled> end
#<disabled> export plot_stations
#<disabled> 
#<disabled> """
#<disabled>     plot_stations(section::Section; draw_coastline::Bool=true, debug::Integer=0, kwargs...)
#<disabled> 
#<disabled> Plot section station locations on a map.
#<disabled> 
#<disabled> The locations are plotted with `scatter`, with aspect ratio computed using
#<disabled> the midpoint between the extrema of `latitude`. If `show_coastline` is true,
#<disabled> then [`plot_coastline`](@ref) is called to draw the land.
#<disabled> 
#<disabled> # Arguments
#<disabled> 
#<disabled> - `section` a [`Section`](@ref).
#<disabled> 
#<disabled> # Keywords
#<disabled> 
#<disabled> - `draw_coastline`: a Bool value indicating whether to plot the coastline,
#<disabled>   using [`plot_coastline`](@ref).
#<disabled> 
#<disabled> - `debug`: an optional value that, if it exceeds 0, indicates that debugging
#<disabled>   output should be printed during processing.
#<disabled> 
#<disabled> - `kwargs`: optional items, passed down to lower-level plotting functions. For
#<disabled>   example, `size` controls the size of the plot, `xlim` and `ylim` control the
#<disabled>   viewing window, `color` controls the land colour, and `markercolor` controls
#<disabled>   the station-location colour.
#<disabled> 
#<disabled> # Examples
#<disabled> 
#<disabled> ```julia
#<disabled> using OceanAnalysis, Plots
#<disabled> url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
#<disabled> dir = get_section(url);
#<disabled> s = read_section(dir);
#<disabled> plot_stations(s, xlim=(-80,0), ylim=(20,50))
#<disabled> ```
#<disabled> """
#<disabled> function plot_stations(section::Section; draw_coastline::Bool=true, debug::Integer=0, kwargs...)
#<disabled>     plot_stations(section["longitude"], section["latitude"]; draw_coastline=draw_coastline, debug=debug, kwargs...)
#<disabled> end
#<disabled> export plot_stations
