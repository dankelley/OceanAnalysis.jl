using OceanAnalysis
using GLMakie # or CairoMakie
cl = coastline();

fig = Figure()
L = (-140, -50, 43, 76) # plot limits: east, west, south, north
l = (-67, -58, 43, 47.5)
# Left panel
plot_coastline!(fig[1, 1], cl, limits=L, linewidth=0.2) # thin lines are prettier
lines!([l[1], l[1], l[2], l[2], l[1]], [l[3], l[4], l[4], l[3], l[3]], color=:red)
# Right panel
plot_coastline!(fig[1, 2], cl, limits=l, scalebar=true)

save("coastline.png", fig, px_per_unit=5)

