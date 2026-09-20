using Statistics, Printf
using GMT: gmtread, xy2lonlat, grdproject

"""
    plot_dem(dem::Dem; coordinates::Symbol=:distance, debug=0, kwargs...)

# Arguments

- `dem` a Dem object

# Keywords

- `coordinates` a Symbol that indicates what to put on the axes. If this is
  `:distance` (the default) then distance (in m) is shown on the axes. Otherwise,
  if it is `:geographic` then longitude and latitude are used (with aspect ratio
  set for the middle latitude).

- `kwargs...` other arguments, passed to `heatmap`, which plots the elevation
  data.

"""
function plot_dem(dem::Dem; coordinates::Symbol=:distance, debug=0, kwargs...)
    # FIXME add debug as an argument
    oad(debug, "plot_dem() START")
    fig = Makie.Figure()
    ax, plot = plot_dem!(fig[1, 1], dem;
        coordinates=coordinates, debug=increment_debug(debug), kwargs...)
    rval = Makie.FigureAxisPlot(fig, ax, plot.main)
    oad(debug, "END plot_dem()")
    return rval
end
export plot_dem


function plot_dem!(fig_pos, dem::Dem; coordinates::Symbol=:distance, debug=0, kwargs...)
    oad(debug, "plot_dem!() START")
    z = permutedims(dem.data)
    if coordinates == :distance
        oad(debug, "    handling coordinates=:distance case")
        x = dem["x"]
        y = dem["y"]
        lims = (extrema(x)..., extrema(y)...)
        aspect_ratio = 1.0
        box_aspect = (lims[2] - lims[1]) / ((lims[4] - lims[3]) * aspect_ratio)
        ax = Makie.Axis(fig_pos[1, 1], aspect=Makie.AxisAspect(box_aspect))
        main = Makie.heatmap!(ax, x, y, z)
    elseif coordinates == :geographic
        oad(debug, "    handling coordinates=:geographic case")
        longitude = dem["longitude"]
        latitude = dem["latitude"]
        middle_lat = latitude[div(end + 1, 2)]
        aspect_ratio = 1.0 / cosd(middle_lat)
        lims = (extrema(longitude)..., extrema(latitude)...)
        box_aspect = (lims[2] - lims[1]) / ((lims[4] - lims[3]) * aspect_ratio)
        ax = Makie.Axis(fig_pos[1, 1], aspect=Makie.AxisAspect(box_aspect))
        main = Makie.heatmap!(ax, dem["longitude"], dem["latitude"], z)
    else
        error("coordinates=$(repr(coordinates)) not permited; try :distance or :geographic")
    end
    oad(debug, "END plot_dem!()")
    return ax, (main=main,)
end
export plot_dem!

