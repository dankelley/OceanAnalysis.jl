using OceanAnalysis, GLMakie
topo_file = get_topography(-67, -63, 43, 46, resolution=1)
topo = read_topography(topo_file);

# Single panel
fig = plot_topography(topo) # domain defaults to :land_and_sea
save("topography_1.png", fig)

# Multiple panels
fig = Figure(size=(800, 200))
plot_topography!(fig[1, 1], topo, domain=:land_and_sea) # same as above
plot_topography!(fig[1, 2], topo, domain=:sea)
plot_topography!(fig[1, 3], topo, domain=:land)
save("topography_2.png", fig)
