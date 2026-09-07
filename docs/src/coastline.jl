using OceanAnalysis, CairoMakie
c = coastline()
fig = plot_coastline(c)
save("coastline.png", fig)
