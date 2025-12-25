using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
dir = get_section(url)
section = read_section(dir);
plot(section, "map")
savefig("section_map.png")

