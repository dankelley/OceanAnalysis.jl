using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
dir = get_section(url)
section = read_section(dir);
longitude = map(ctd -> get_element(ctd, "longitude"), section.data);
latitude = map(ctd -> get_element(ctd, "latitude"), section.data);
plot(longitude, latitude,
    aspect_ratio=1.0 / cos(0.5 * sum(extrema(latitude)) * pi / 180),
    seriestype=:scatter, framestyle=:box, legend=false, ms=2)
plot_coastline!(coastline())
savefig("section_map.png")

