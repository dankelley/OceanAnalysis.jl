using OceanAnalysis
using GLMakie # or CairoMakie
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].<(-68.0)];
# We must grid to get the cross-section diagrams
sg = grid_section(s);
fig = plot_section(sg, which="salinity", type=:contourf)
save("section.png", fig, px_per_unit=2)

