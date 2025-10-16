using OceanAnalysis, Plots
cl = coastline();

plot_coastline(cl, xlim=(-70, -60), ylim=(42, 48), aspect_ratio=1 / cos(45 * pi / 180),
    dpi=200)
add_scale_bar = function (distance::Real=100.0, x=:topleft, y=:topleft)
    (x == :topleft && y == :topleft) || error("x and y must both be :topleft")
    xlim = xlims()
    ylim = ylims()
    ymid = (ylim[1] + ylim[2]) / 2.0
    km_per_degree_lon = geod_distance(xlim[1] - 0.5, ymid, xlim[1] + 0.5, ymid)
    dx = (xlim[2] - xlim[1]) / 20
    dy = (ylim[2] - ylim[1]) / 20
    y0 = ylim[2] - dy
    X = xlim[1] + dx .+ [0.0, distance / km_per_degree_lon]
    Y = [y0, y0]
    plot!(X, Y, color=:black, linewidth=2)
    annotate!((X[1] + X[2]) / 2.0, y0 + dy / 2,
        Plots.text("$(trunc(Int, distance)) km", 8))
end
add_scale_bar(100.0)
savefig("scalebar_01.png")

