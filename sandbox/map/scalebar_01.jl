using OceanAnalysis, Plots
cl = coastline();

plot_coastline(cl, xlim=(-70, -60), ylim=(42, 48), aspect_ratio=1 / cos(45 * pi / 180), dpi=200)
scale_bar(100.0)
scale_bar(100.0, :right, :top)
scale_bar(100.0, :right, :bottom)
scale_bar(100.0, :left, :bottom)
savefig("scalebar_01.png")

