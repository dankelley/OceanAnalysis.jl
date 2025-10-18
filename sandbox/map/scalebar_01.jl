using OceanAnalysis, Plots
cl = coastline();

plot_coastline(cl, xlim=(-70, -60), ylim=(42, 48), aspect_ratio=1 / cos(45 * pi / 180), dpi=200)
scale_bar(100.0)
scale_bar(100.0, :right, :top)
scale_bar(100.0, :right, :bottom)
scale_bar(100.0, :left, :bottom)
#savefig("scalebar_01.png")
plot!([-70, -60], [43, 43], color=:red)
plot!([-65, -65], [42, 48], color=:red)

scale_bar(100, -65, 42.5)
scale_bar(100, -65, 43, linewidth=5, fontsize=12)
