using Makie, CairoMakie
using GeoMakie, GeoMakie.GeoJSON
function default_fig()
    Figure(
        resolution=(1920, 1080),
        fontsize=50,
        figure_padding=(100, 100, 100, 100)
    )
end

fig = default_fig()
ax = Axis(fig[1, 1])
fig
