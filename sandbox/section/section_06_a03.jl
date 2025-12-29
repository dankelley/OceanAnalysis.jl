using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip" # exchange format
dir = get_section(url)
s = read_section(dir);
s.data = s.data[s["longitude"].<-68.0];
p1 = plot_section(s, xlim=(-80, -65), ylim=(35, 43))
scale_bar(500)
sg = grid_section(s);
levels = 30.0:0.5:40.0
p2 = plot_section(sg, "salinity", contourlabels=true, color=:black, cbar=false, ylim=(0, 2000), yflip=true, debug=1)
#p3 = plot_section(sg, "temperature", contourlabels=true, color=:black, cbar=false, ylim=(0, 2000), yflip=true, debug=1)
plot(p1, p2)
savefig("section_06_salinity.pdf")

