using OceanAnalysis, Plots
topo_file = get_topography(-67, -63, 43, 46, resolution=1)
topo = read_topography(topo_file);
fs = 7
p1 = plot_topography(topo, domain=:both, fontsize=fs);
p2 = plot_topography(topo, domain=:sea, fontsize=fs);
p3 = plot_topography(topo, domain=:land, fontsize=fs);
plot(p1, p2, p3, layout=(1, 3), size=(800, 200), dpi=200)
savefig("topography.png")
