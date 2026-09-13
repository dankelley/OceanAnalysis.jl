# 1. put fontsize in kwargs...
# FIXME: rewrite as Makie
"""
    plot_topography(topo::Topography;
        xlims=:auto, ylims=:auto, tickdirection=:out,
        domain=:sea, color=:land_sea, clim=:auto,
        draw_coastline=true, land_color=:bisque3, sea_color=:lightblue,
        debug::Integer=0, kwargs...)

Draw a `heatmap` image of topography.

The `domain` argument tells whether to display both land and sea values, or
just land, or just sea. The default is to plot just the sea, with land a light
brown color.

# Arguments

- `topo` a Topography object, as read by [`read_topography`](@ref).

# Keywords

- `domain` indicates whether to display both land and sea values, or
just land, or just sea. The default is to plot just the sea, with land a light
brown color.

- `color` ??? 

- `clim` ??? 

- `draw_coastline` non-function FIXME

- `land_color` FIXME

- `sea_color` FIXME

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

- `kwargs` Other keyword arguments. Use `fontsize` (which defaults to 8) to set
  the font size for axes and titles. Use `title` (which defaults to an empty
  string) to set the title of the plot.

# Examples

```julia
# Waters near Prince Edward Island, Canada
using OceanAnalysis
topo_file = get_topography(-64.8, -61.5, 45.6, 47.2, resolution=1)
topo = read_topography(topo_file)
plot_topography(topo)
```
"""
function plot_topography(topo::Topography;
    domain=:sea, color=:land_sea, clim=:auto,
    draw_coastline=true, land_color=:bisque3, sea_color=:lightblue,
    debug::Integer=0, kwargs...)
    fig = Figure()
    plot_topography!(fig[1, 1], topo, domain=domain, color=color, clim=clim,
        draw_coastline=draw_coastline, land_color=land_color, sea_color=sea_color,
        debug=increment_debug(debug), kwargs...)
    return fig
    oad(debug, "END plot_topography()")
end
export plot_topography

function plot_topography!(fig_pos, topo::Topography;
    domain=:sea, color=:land_sea, clim,
    draw_coastline=true, land_color=:bisque3, sea_color=:lightblue,
    debug::Integer=0, kwargs...)
    oad(debug, "plot_topography!() BEGIN")
    domain in (:sea, :land, :both) || throw(ArgumentError("domain $(repr(domain)) not permited; use :sea, :land, or :both"))
    oad(debug, "    domain= :", domain)
    oad(debug, "    land_color= :", land_color)
    oad(debug, "    sea_color= :", sea_color)
    oad(debug, "    processing kwargs...")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "        • fontsize=$fontsize")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "        • title=\"$title\"")
    if !isempty(kwargs_dict)
        error("plot_topography!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: fontsize and title")
    end
    longitude = copy(topo["longitude"]) # FIXME: do we need to copy?
    latitude = copy(topo["latitude"]) # FIXME: do we need to copy?
    data = copy(topo.data) # FIXME: do we need to copy?
    aspect_ratio = 1.0 / cos(0.5 * (latitude[1] + latitude[end]) * pi / 180.0)
    xlim = extrema(longitude)
    ylim = extrema(latitude)
    box_aspect = (xlim[2] - xlim[1]) / ((ylim[2] - ylim[1]) * aspect_ratio)
    oad(debug, "    aspect_ratio=$aspect_ratio, box_aspect=$box_aspect")
    # FIXME: fix as for coastline and amsr
    ax = Axis(fig_pos[1, 1],
        aspect=AxisAspect(box_aspect),
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)

    oad(debug, "    data extrema: ", extrema(filter(!isnan, data)))
    if domain == :sea
        data .= -data
        data[data.<0.0] .= NaN
        oad(debug, "    setting land values to NaN")
        if color == :land_sea
            oad(debug, "    setting colorscheme to reversed first half of :topo")
            color = [get(ColorSchemes.topo, i) for i in 0.5:-0.6/1000:0.0]
        end
    elseif domain == :land
        data[data.<0.0] .= NaN
        oad(debug, "    setting sea values to NaN")
        if color == :land_sea
            oad(debug, "    setting colorscheme to second half of :topo")
            color = [get(ColorSchemes.topo, i) for i in 0.5:0.6/1000:1.0]
        end
    elseif domain == :both
        if color == :land_sea
            oad(debug, "    setting colorscheme to :topo")
            color = :topo
        end
    end
    if clim == :auto
        if domain == :both
            clim = maximum(abs.(filter(!isnan, data))) .* (-1.0, 1.0)
        else
            clim = extrema(filter(!isnan, data))
        end
        oad(debug, "    clim defaulting to ", clim)
    end
    if domain == :sea
        background_color_inside = land_color
    elseif domain == :land
        background_color_inside = sea_color
    else
        background_color_inside = :transparent
    end
    hm_plt = heatmap!(ax, longitude, latitude, permutedims(data)) # FIXME:use colormap etc
    cb_plt = Colorbar(fig_pos[1, 2], hm_plt, ticklabelsize=fontsize)
    if draw_coastline == "FIXME"
        # FIXME: this is definitely wrong
        oad(debug, "    plotting the coastline")
        cl = coastline()
        plot!(p, cl.data.longitude, cl.data.latitude, lw=0.5, seriestype=:path, color=:black, legend=false; kwargs...)
    end
    oad(debug, "END plot_topography!()")
    return (ax=ax, plt=hm_plt, cb=cb_plt)
end
export plot_topography!

