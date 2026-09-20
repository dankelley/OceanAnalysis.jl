"""
    plot_topography(topo::Topography;
        domain=:sea, land_color=:bisque3, sea_color=:lightblue,
        draw_coastline=true, debug::Integer=0, kwargs...)

    plot_topography!(fig_pos, topo::Topography;
        domain=:sea, land_color=:bisque3, sea_color=:lightblue,
        draw_coastline=true, debug::Integer=0, kwargs...)

Draw a `heatmap` image of topography.

# Arguments

- `topo` a Topography object, as read by [`read_topography`](@ref).

# Keywords

- `domain` a Symbol that indicates what to display with a heatmap. The valid
  choices are `:land`, `:sea` and `:land_and_sea`.

- `draw_coastline` Bool value indicating whether to draw the coastline (true by
  default)

- `land_color` color used to fill the land -- FIXME, as not coded yet.

- `sea_color` color used to fill the land -- FIXME, as not coded yet.

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

  - `kwargs` Other keyword arguments. You may use `colorrange` to set the range
  for the values being coloured (which defaults to the data range). Use
  `fontsize` (which defaults to 8) to set the font size for axes and
  titles. Use `title` (which defaults to an empty string) to set the
  title of the plot.

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
    domain=:sea, land_color=:bisque3, sea_color=:lightblue,
    draw_coastline=true, debug::Integer=0, kwargs...)
    fig = Makie.Figure()
    plot_topography!(fig[1, 1], topo;
        domain=domain, land_color=land_color, sea_color=sea_color,
        draw_coastline=draw_coastline, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_topography()")
    return fig
end
export plot_topography

function plot_topography!(fig_pos, topo::Topography;
    domain=:sea, land_color=:bisque3, sea_color=:lightblue,
    draw_coastline=true, debug::Integer=0, kwargs...)
    oad(debug, "plot_topography!() BEGIN")
    domain in (:sea, :land, :land_and_sea) || throw(ArgumentError("domain $(repr(domain)) not permited; use :sea, :land, or :land_and_sea"))
    oad(debug, "    domain= :", domain)
    oad(debug, "    land_color= :", land_color)
    oad(debug, "    sea_color= :", sea_color)
    oad(debug, "    processing kwargs...")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    #<not user-controlled in this version> colormap = pop!(kwargs_dict, :colormap, :inferno)
    #<not user-controlled in this version> oad(debug, "        • colormap= :$colormap")
    colorrange = pop!(kwargs_dict, :colorrange, :auto)
    if colorrange == :auto
        oad(debug, "        • colorrange=$colorrange (i.e., will use data range)")
    else
        oad(debug, "        • colorrange=$colorrange")
    end
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "        • fontsize=$fontsize")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "        • title=\"$title\"")
    if !isempty(kwargs_dict)
        error("plot_topography!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: colorrange, fontsize and title")
    end
    longitude = copy(topo["longitude"]) # no need to copy, but it's small
    latitude = copy(topo["latitude"]) # no need to copy, but it's small
    data = copy(topo.data) # we may multiply by -1 here, so must copy
    xlim = extrema(longitude)
    ylim = extrema(latitude)
    aspect_ratio = 1.0 / cos(0.5 * sum(ylim) * pi / 180.0)
    box_aspect = (xlim[2] - xlim[1]) / ((ylim[2] - ylim[1]) * aspect_ratio)
    oad(debug, "    aspect_ratio=$aspect_ratio, box_aspect=$box_aspect")
    # FIXME: fix as for coastline and amsr
    ax = Makie.Axis(fig_pos[1, 1],
        aspect=Makie.AxisAspect(box_aspect),
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)

    oad(debug, "    data extrema: ", extrema(filter(!isnan, data)))
    if domain == :sea
        oad(debug, "    setting land values to NaN")
        data[data.>0.0] .= NaN
        data .= -data
        oad(debug, "    setting colorscheme to reversed first half of ColorSchemes.topo")
        colormap = [get(ColorSchemes.topo, i) for i in 0.5:-0.6/1000:0.0]
    elseif domain == :land
        oad(debug, "    setting sea values to NaN")
        data[data.<0.0] .= NaN
        oad(debug, "    setting colorscheme to second half of ColorSchemes.topo")
        colormap = [get(ColorSchemes.topo, i) for i in 0.5:0.6/1000:1.0]
    elseif domain == :land_and_sea
        oad(debug, "    setting colorscheme to ColorSchemes.topo")
        colormap = ColorSchemes.topo
    end
    if colorrange == :auto
        if domain == :land_and_sea
            colorrange = maximum(abs.(filter(!isnan, data))) .* (-1.0, 1.0)
            oad(debug, "    colorrange defaulting to ", colorrange, " domain == :land_and_sea")
        else
            colorrange = extrema(filter(!isnan, data))
            oad(debug, "    colorrange defaulting to ", colorrange, " domain != :land_and_sea")
        end
    end
    if domain == :sea
        background_color_inside = land_color
    elseif domain == :land
        background_color_inside = sea_color
    else
        background_color_inside = :transparent
    end
    oad(debug, "    drawing the heatmap")
    if domain == :land_and_sea
        nan_color = :white
    elseif domain == :sea
        nan_color = land_color
    elseif domain == :land
        nan_color = sea_color
    end
    hm_plt = Makie.heatmap!(ax, longitude, latitude, permutedims(data),
        colormap=colormap, colorrange=colorrange,
        nan_color=nan_color)
    if draw_coastline
        lims = Makie.ax.finallimits[]
        Makie.limits!(ax,
            lims.origin[1], lims.origin[1] + lims.widths[1],
            lims.origin[2], lims.origin[2] + lims.widths[2])
        oad(debug, "    drawing coastline")
        cl = coastline()
        Makie.lines!(ax, cl["longitude"], cl["latitude"], color=:black)
    end
    oad(debug, "    drawing the Colorbar")
    cb_plt = Makie.Colorbar(fig_pos[1, 2], hm_plt, ticklabelsize=fontsize)
    oad(debug, "END plot_topography!()")
    return (ax=ax, plt=hm_plt, cb=cb_plt)
end
export plot_topography!

