using OceanAnalysis, Plots, Statistics
dir = "/Users/kelley/ar07_74JC20140606"
files = readdir(dir)
nfiles = length(files)
nfiles > 0 || error("no ctd files found in $dir")
# Next takes 0.167s for 234 files (7 ms per file)
ctds = map((file) -> read_ctd_exchange(joinpath(dir, file)), files)
longitude = map((ctd) -> get_element(ctd, "longitude"), ctds)
latitude = map((ctd) -> get_element(ctd, "latitude"), ctds)
aspect_ratio = 1.0 / cos(mean(extrema(latitude)) * pi / 180)
plot(longitude, latitude, aspectratio=aspect_ratio,
    seriestype=:scatter, framestyle=:box, legend=false, ms=1)
plot_coastline!(coastline(), color=:lightgray)
savefig("section_03.png")
