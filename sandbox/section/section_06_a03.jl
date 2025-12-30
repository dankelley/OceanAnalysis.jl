using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].<-68.0];
sg = grid_section(s);
A = plot_section(sg, xlim=(-80, -60), ylim=(35, 40))
B = plot_section(sg, "salinity", type=:heatmap)
C = plot_section(sg, "salinity", ylim=(0, 1000), type=:heatmap)
plot(A, B, C, layout=@layout[A; B C], dpi=300, type=:heatmap)
savefig("section_06_a03.png")

