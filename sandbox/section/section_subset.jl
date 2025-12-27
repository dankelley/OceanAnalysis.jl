using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip";
dir = get_section(url);
s0 = read_section(dir);

# Select a coastal region on Labrador shelf
lon = s0["longitude"]
lat = s0["latitude"]
ll = (-56, 52)
ur = (-51.7, 54)
look = (ll[1] .<= lon .<= ur[1]) .& (ll[2] .<= lat .<= ur[2])
println("keeping ", round(100 * sum(look) / length(look), digits=2), "% of the data")

p1 = plot_section(s0);
plot!([ll[1], ll[1], ur[1], ur[1], ll[1]], [ll[2], ur[2], ur[2], ll[2], ll[2]], color=:red);
s = Section(s0.metadata, s0.data[look]);
p2 = plot_section(s);
p2 = plot_section(s);
p3 = plot(s0["longitude"], s0["depth"], seriestype=:scatter, legend=false, framestyle=:box, markersize=2);
p4 = plot(s["longitude"], s["depth"], seriestype=:scatter, legend=false, framestyle=:box, markersize=2);
plot(p1, p2, p3, p4)
savefig("section_subset.pdf")
