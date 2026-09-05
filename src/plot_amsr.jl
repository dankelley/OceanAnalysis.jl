"""
    plot_amsr(amsr::Amsr; xlims=(0.0, 360.0), ylims=(-90.0, 90.0),
              draw_coastline=true, draw_contours=:none,
              fontsize=8, debug::Integer=0, kwargs...)

Plot a heatmap of a field in an [`Amsr`](@ref) object, using Makie.jl. By
default, SST is shown using the `:turbo` colorscheme, and the view is of the
whole earth. For "daily" datasets (see the `type` argument of the
[`get_amsr`](@ref) function), the ascending and descending swaths are
averaged.

Note: this function requires a Makie backend to be loaded and activated by
the caller (e.g. `using CairoMakie` or `using GLMakie`) before it is called.

# Arguments
- `amsr`: An [`Amsr`](@ref) object, as read by [`read_amsr`](@ref).

# Keywords
- `xlims`: a tuple giving the range of longitude to be shown. This is based on
  the 0 to 360 notation, since that is how AMSR data are stored.
- `ylims`: a tuple giving the range of latitude to be shown. This is based on
  the -90 to 90 notation.
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
  through to `Makie.heatmap!`. For example, specify a value for `colormap` to
  change the palette. `title` may also be supplied, and will be applied to
  the Axis.

# Return value
`plot_amsr` returns a `Makie.Figure`, which can be displayed directly or
saved with `save("filename.png", fig)`.

# Examples
```julia
using OceanAnalysis, CairoMakie

file = get_amsr()

# 1. SST heatmap
sst = read_amsr(file, "SST");
plot_amsr(sst; xlims=(260, 360), ylims=(20, 60),
    title="Sea-surface Temperature [°C]")

# 2. SST heatmap with 1km depth shown
fig = plot_amsr(sst; xlims=(275.0, 350.0),
    ylims=(20.0, 65.0), colorrange=(-2.0, 30.0),
    title="Sea-surface Temperature [°C] with 1-km isobath")
ax = fig[1, 1]
tf = get_topography()
t = read_topography(tf);
# NB: transpose data and draw twice since -180<toopography longitude<180
contour!(ax, t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
contour!(ax, 360.0 .+ t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
fig
```
"""
function plot_amsr(amsr::Amsr; xlims=(0.0, 360.0), ylims=(-90.0, 90.0),
    draw_coastline=true, draw_contours=:none,
    fontsize=8, debug::Integer=0, kwargs...)
    2 == length(xlims) || throw(ArgumentError("xlims must be of length 2"))
    2 == length(ylims) || throw(ArgumentError("ylims must be of length 2"))
    oad(debug, "plot_amsr() START")
    oad(debug, "  xlims: $xlims, ylims: $ylims")
    longitude = amsr.metadata["longitude"]
    latitude = amsr.metadata["latitude"]
    oad(debug, "  plotting a heatmap of ", amsr.metadata["field"])

    # Emulate Plots' data-based aspect_ratio (1 unit of latitude drawn taller
    # than 1 unit of longitude near the poles) via Makie's AxisAspect, which
    # controls the on-screen box shape rather than a literal data scaling.
    aspect_ratio = 1.0 / cos(pi * 0.5 * (ylims[1] + ylims[2]) / 180.0)
    box_aspect = (xlims[2] - xlims[1]) / ((ylims[2] - ylims[1]) * aspect_ratio)

    kwargs_dict = Dict{Symbol,Any}(kwargs)
    title = pop!(kwargs_dict, :title, "")

    fig = Figure()
    ax = Axis(fig[1, 1],
        title=title,
        xlabel="Longitude",
        ylabel="Latitude",
        aspect=AxisAspect(box_aspect),
        xlabelsize=fontsize + 4, ylabelsize=fontsize + 4, titlesize=fontsize + 4,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    limits!(ax, xlims[1], xlims[2], ylims[1], ylims[2])

    # Makie's heatmap!(x, y, z) expects z sized (length(x), length(y)), the
    # transpose of what Plots' heatmap(x, y, z) expected.
    colormap = pop!(kwargs_dict, :colormap, :turbo)
    colorrange = pop!(kwargs_dict, :colorrange, (-5.0, 35.0))
    hm = heatmap!(ax, longitude, latitude, permutedims(amsr.data);
        colormap=colormap, colorrange=colorrange, kwargs_dict...)
    Colorbar(fig[1, 2], hm)

    # Possibly draw the land
    if draw_coastline
        oad(debug, "  drawing the land and coastline")
        if ylims[2] - ylims[1] > 50
            oad(debug, "  defaulting to coastline(:global_coarse)")
            cl = coastline(:global_coarse)
        else
            oad(debug, "  defaulting to coastline(:global_fine)")
            cl = coastline(:global_fine)
        end
        draw_coastline_polygons!(ax, cl.data.longitude, cl.data.latitude,
            debug=increment_debug(debug))
        if any(xlims .> 180.0)
            draw_coastline_polygons!(ax, cl.data.longitude .+ 360, cl.data.latitude,
                debug=increment_debug(debug))
        end
    else
        oad(debug, "  not drawing the land or coastline")
    end

    # Possibly draw contours
    if draw_contours != :none
        if draw_contours == :auto
            oad(debug, "  adding auto-selected contours")
            contour!(ax, longitude, latitude, permutedims(amsr.data),
                levels=range(-5.0, 35.0, step=5.0), color=:black,
                linewidth=0.75)
        elseif isa(draw_contours, AbstractVector) && eltype(draw_contours) <: Real
            oad(debug, "  adding user-specified contours")
            contour!(ax, longitude, latitude, permutedims(amsr.data),
                levels=draw_contours, color=:black,
                linewidth=0.75)
        else
            @warn "draw_contours ($draw_contours) cannot be handled; try :none, :auto, or a numeric vector"
        end
    end

    oad(debug, "END plot_amsr()")
    return fig
end
export plot_amsr

"""
    draw_coastline_polygons!(ax, longitude, latitude; color=:bisque3, debug=0)

Helper for [`plot_amsr`](@ref). Coastline data are stored as `longitude` and
`latitude` vectors with `NaN` separating individual land-mass rings (this is
the convention Plots' `seriestype=:shape` relied on). Makie has no direct
equivalent, so this splits the vectors on `NaN` and fills each ring
separately with `poly!`.
"""
function draw_coastline_polygons!(ax, longitude, latitude; color=:bisque3, debug=0)
    oad(debug, "draw_coastline_polygons!() START")
    polygons = Polygon{2,Float32}[]
    start = 1
    n = length(longitude)
    oad(debug, "  assembling polygons")
    for i in 1:n+1
        if i == n + 1 || isnan(longitude[i]) || isnan(latitude[i])
            if i - start >= 3
                ring = Point2f.(longitude[start:i-1], latitude[start:i-1])
                push!(polygons, Polygon(ring))
            end
            start = i + 1
        end
    end
    oad(debug, "  plotting the assembled polygons")
    if !isempty(polygons)
        poly!(ax, polygons, color=color, strokewidth=0.5, strokecolor=:black)
    end
    oad(debug, "END draw_coastline_polygons!()")
end

