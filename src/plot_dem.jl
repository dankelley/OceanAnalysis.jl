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

- `debug` indicator of debugging level. If this exceeds 0, some information is
  printed during processing.

- `kwargs...` extra arguments that are parsed and handled accordingly. The
  permitted keywords are: `colormap` (which defaults to `:inferno`
  if not supplied), `colorrange` (which defaults to the extrema
  of the elevation, if not supplied), `fontsize` (which defaults
  to 8 if not supplied), and `title` (which defaults to `""`, if
  not supplied).
"""
function plot_dem(dem::Dem; coordinates::Symbol=:distance, debug=0, kwargs...)
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
    # infer keyword arguments
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    oad(debug, "    inferred the following from kwargs (or from defaults, or from the data):")
    colormap = pop!(kwargs_dict, :colormap, :inferno)
    oad(debug, "      • colormap:    $(oad_val(colormap))")
    colorrange = pop!(kwargs_dict, :colorrange, :auto)
    oad(debug, "      • colorrange:  $(colorrange)")
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "      • fontsize:    $(oad_val(fontsize))")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "      • title:       $(oad_val(title))")
    # Check for unhandled keywords
    if !isempty(kwargs_dict)
        error("plot_dem!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: colormap, colorrange, ",
            "fontsize, and title")
    end
    oad(debug, "    plotting the data")
    if colorrange == :auto
        colorrange = extrema(xx for xx in skipmissing(dem.data) if !isnan(xx))
        oad(debug, "    colorrange defaulted to data extrema: $colorrange")
    end
    if coordinates == :distance
        oad(debug, "    handling coordinates=:distance case")
        x = dem["x"]
        y = dem["y"]
        lims = (extrema(x)..., extrema(y)...)
        aspect_ratio = 1.0
        box_aspect = (lims[2] - lims[1]) / ((lims[4] - lims[3]) * aspect_ratio)
        ax = Makie.Axis(fig_pos[1, 1], aspect=Makie.AxisAspect(box_aspect),
            title=title,
            xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
            xticklabelsize=fontsize, yticklabelsize=fontsize)
        main = Makie.heatmap!(ax, x, y, z,
            colormap=colormap, colorrange=colorrange)
    elseif coordinates == :geographic
        oad(debug, "    handling coordinates=:geographic case")
        longitude = dem["longitude"]
        latitude = dem["latitude"]
        middle_lat = latitude[div(end + 1, 2)]
        aspect_ratio = 1.0 / cosd(middle_lat)
        lims = (extrema(longitude)..., extrema(latitude)...)
        box_aspect = (lims[2] - lims[1]) / ((lims[4] - lims[3]) * aspect_ratio)
        ax = Makie.Axis(fig_pos[1, 1], aspect=Makie.AxisAspect(box_aspect),
            title=title,
            xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
            xticklabelsize=fontsize, yticklabelsize=fontsize)
        main = Makie.heatmap!(ax, dem["longitude"], dem["latitude"], z,
            colormap=colormap, colorrange=colorrange)
    else
        error("coordinates=$(repr(coordinates)) not permited; try :distance or :geographic")
    end
    oad(debug, "END plot_dem!()")
    return ax, (main=main,)
end
export plot_dem!

