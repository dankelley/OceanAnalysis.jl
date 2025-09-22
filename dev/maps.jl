# Plot world coastline earth with the coarse dataset and Nova Scotia with the fine dataset
using OceanAnalysis, Plots
# Left: world view
p1 = plot_coastline(coastline(:global_coarse))
# Right: Nova Scotia view
p2 = plot_coastline(coastline(:global_fine), xlims=(-68, -59), ylims=(42, 48))
l = @layout [a{0.6w} b{0.4w}]
plot(p1, p2, layout=l)
savefig("maps.png")
