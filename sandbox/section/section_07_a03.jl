using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].<-68.0];
sg = grid_section(s);

p1 = plot_section(sg, "salinity", ylim=(0, 1000))
p2 = plot_section(sg, "salinity", ylim=(0, 1000), show_stations=true)
plot(p1, p2, dpi=200)

savefig("section_07_a03.png")

