"""
    plot_amsr(amsr::Amsr; limits=(0.0, 360, -90.0, 90.0),
        draw_coastline=true, draw_contours=:none,
        fontsize=8, debug::Integer=0, kwargs...)

    plot_amsr!(fig_posamsr::Amsr; limits=(0.0, 360, -90.0, 90.0),
        draw_coastline=true, draw_contours=:none,
        fontsize=8, debug::Integer=0, kwargs...)

Plot a heatmap of a field in an [`Amsr`](@ref) object, using Makie.jl. By
default, SST is shown using the `:turbo` colorscheme, and the view is of the
whole earth. For "daily" datasets (see the `type` argument of the
[`get_amsr`](@ref) function), the ascending and descending swaths are
averaged.

These functions require a Makie backend to be loaded and activated by
the caller (e.g. `using CairoMakie` or `using GLMakie`) before it is called.

# Return value

The `plot_amsr` form returns a `Makie.Figure`, which can be displayed
directly or saved with `save("filename.png", fig)`.

The `plot_amsr!` form returns a NamedTuple containing `ax` (a `Makie.Axis`),
`plt` (a Makie `Heatmap` object) and `cb` (a Colorbar object).

These functions require a Makie backend to be loaded and activated by
the caller (e.g. `using CairoMakie` or `using GLMakie`) before they
are called.

# Arguments

- `amsr`: An [`Amsr`](@ref) object, as read by [`read_amsr`](@ref).

# Keywords

- `limits`: a 4-element tuple giving, in order, the minimum longitude to show,
  the maximum longitude, the minimum latitude, and finally the maximum latitude.
  The default is to show the whole planet.

- `draw_coastline`: a Bool indicating whether to draw the coastline.
  If you want to contour something (e.g. depth) on top of the
  image, you must set `draw_coastline=false`, do your drawing
  after that, and finally add the coastline yourself (e.g. via a
  Makie-based `plot_coastline!` equivalent) so that it is drawn on top.

- `draw_contours`: either a symbol or a numeric vector that controls contours
  that may be added to the heatmap. If this is `:none` (which is the default),
  then no contours are drawn. If it is `:auto` then contours are drawn at 5°C
  increments. And, finally, if it is a vector of numeric elements, then
  contours are drawn (unlabelled) at those values.

- `fontsize`: size of fonts used for tick labels, axis labels, and the title.

- `debug`: An integer controlling whether to print information during
  processing. The default is to work silently; use any positive value to get
  some printing.

- `kwargs...` optional other arguments to customize the heatmap plot, passed
  through to `Makie.heatmap!`, e.g. set `colormap` and/or
  `colorrange` to control the palette; set `limits` to control the plot
  longitude and latitude limits; set `title` for the title, and set
  `xlab` and `ylab` to specify axis names.

# Return value

`plot_amsr` returns a `Makie.Figure`, which can be displayed directly or
saved with `save("filename.png", fig)`.  See Example 2 for how to add
a depth contour to the image created by `plot_amsr`.

# Examples
```julia
using OceanAnalysis, CairoMakie
using Dates # for time format

file = get_amsr()
sst = read_amsr(file, "SST");

# 1. SST heatmap of Northwest Atlantic.
plot_amsr(sst; limits=(260, 360, 20, 60), title="SST")

# 2. As example 1, but also showing the 1km isobath
fig = Figure(size=(600,310))
plot_amsr!(fig, sst; limits=(260, 360, 20, 60), title="SST")
tf = get_topography()
t = read_topography(tf);
# NB: transpose data (needed for Makie), and draw twice,
# since -180<=longitude<=180 for topographic data,
# as opposed to 0<=longitude<=360 for AMSR data.
contour!(fig[1,1], t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
contour!(fig[1,1], 360.0 .+ t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
fig
```
"""
function plot_amsr(amsr::Amsr; limits=(0.0, 360, -90.0, 90.0),
    draw_coastline=true, draw_contours=:none,
    fontsize=8, debug::Integer=0, kwargs...)
    oad(debug, "plot_amsr() BEGIN (this calls plot_amsr!() after creating a Figure")
    fig = Figure()
    plot_amsr!(fig[1, 1], amsr; limits=limits,
        draw_coastline=draw_coastline, draw_contours=draw_contours,
        fontsize=fontsize, debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_amsr()")
    return fig
end
export plot_amsr

function plot_amsr!(fig_pos, amsr::Amsr;
    draw_coastline=true, draw_contours=:none,
    fontsize=8, debug::Integer=0, kwargs...)
    oad(debug, "plot_amsr!() START")
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    limits = pop!(kwargs_dict, :limits, (0.0, 360, -90.0, 90.0))
    oad(debug, "    limits: $limits")
    # Set the aspect ratio (different in Makie compared with Plots)
    aspect_ratio = 1.0 / cos(pi * 0.5 * (limits[3] + limits[4]) / 180.0)
    box_aspect = (limits[2] - limits[1]) / ((limits[4] - limits[3]) * aspect_ratio)
    oad(debug, "    aspect_ratio=$aspect_ratio, box_aspect=$box_aspect")
    # get the data
    longitude = amsr.metadata["longitude"]
    latitude = amsr.metadata["latitude"]
    z = amsr.data'
    # Finally, get remaining keywords
    colormap = pop!(kwargs_dict, :colormap, :turbo)
    oad(debug, "    colormap: $colormap")
    colorrange = pop!(kwargs_dict, :colorrange,
        extrema(zz for zz in skipmissing(z) if !isnan(zz)))
    oad(debug, "    colorrange: $colorrange")
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "    title: $title")
    xlab = pop!(kwargs_dict, :xlab, "")
    oad(debug, "    xlab: $xlab")
    ylab = pop!(kwargs_dict, :ylab, "")
    oad(debug, "    ylab: $ylab")
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: colormap, colorrange, ",
            "limits, title, xlab, and ylab.")
    end
    ax = Axis(fig_pos[1, 1],
        title=title,
        xlabel=xlab,
        ylabel=ylab,
        aspect=AxisAspect(box_aspect),
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    limits!(ax, limits...)
    # Transpose amsr.data for Makie (not done for Plots).
    oad(debug, "    plotting a heatmap of ", amsr.metadata["field"], " with colormap=:$colormap and colorrange=$colorrange")
    plt = heatmap!(ax, longitude, latitude, permutedims(amsr.data);
        colormap=colormap, colorrange=colorrange, kwargs_dict...)

    # Possibly draw the land
    if draw_coastline
        oad(debug, "    drawing the land and coastline")
        if limits[4] - limits[3] > 50
            oad(debug, "    defaulting to coastline(:global_coarse)")
            cl = coastline(:global_coarse)
        else
            oad(debug, "    defaulting to coastline(:global_fine)")
            cl = coastline(:global_fine)
        end
        draw_coastline_polygons!(ax, cl.data.longitude, cl.data.latitude,
            debug=increment_debug(debug))
        if any(limits[1:2] .> 180.0)
            draw_coastline_polygons!(ax, cl.data.longitude .+ 360, cl.data.latitude,
                debug=increment_debug(debug))
        end
    else
        oad(debug, "    not drawing the land or coastline")
    end

    # Possibly draw contours
    if draw_contours != :none
        if draw_contours == :auto
            oad(debug, "    adding auto-selected contours")
            contour!(ax, longitude, latitude, permutedims(amsr.data),
                levels=range(-5.0, 35.0, step=5.0), color=:black,
                linewidth=0.75)
        elseif isa(draw_contours, AbstractVector) && eltype(draw_contours) <: Real
            oad(debug, "    adding user-specified contours")
            contour!(ax, longitude, latitude, permutedims(amsr.data),
                levels=draw_contours, color=:black,
                linewidth=0.75)
        else
            @warn "draw_contours ($draw_contours) cannot be handled; try :none, :auto, or a numeric vector"
        end
    end
    cb = Colorbar(fig_pos[1, 2], plt, ticklabelsize=fontsize)
    oad(debug, "END plot_amsr!()")
    return (ax=ax, plt=plt, cb=cb)
end
export plot_amsr!

