using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip";
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].<-68.0];
gs = grid_section(s);

plot_section(gs)
plot_section(gs, xvar=("something", gs["latitude"]))
#savefig("0.png")
