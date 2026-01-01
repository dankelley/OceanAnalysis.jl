using NCDatasets, Plots, Downloads, CSV, DataFrames, Dates

# I had to download this file manually from
# https://uhslc.soest.hawaii.edu/opendap/rqds/atlantic/hourly/h275a.nc.html
# since it does not offer saveable links (only button actions).
file = "h275a.nc.nc4" # no API to get this, 
nc = NCDataset(file);
keys(nc)
time = nc["time"][:, 1];
sea_level = nc["sea_level"][:, 1];
println("Original data length: ", length(sea_level))
bad = ismissing.(sea_level);
time = time[bad.!=1];
sea_level = sea_level[bad.!=1];
println("After trimming missing, data length: ", length(sea_level))

mm_per_inch = 25.4

sea_level_inch = sea_level / mm_per_inch;
p1 = scatter(time, sea_level, label=false, markersize=0.25, markercolor=:black,
    framestyle=:box, ylab="Elevation [mm]",
    tickdirection=:out, tickfontsize=6, guidefontsize=6);
y = mm_per_inch * rem.(abs.(sea_level_inch), 1.0 / 16.0, RoundNearest);
p2 = scatter(time, y, label=false, markersize=0.25, markercolor=:black,
    framestyle=:box, ylab="Deviation from nearest 1/16-th inch [mm]",
    tickdirection=:out, tickfontsize=6, guidefontsize=6);
plot(p1, p2, layout=(2, 1), dpi=500);
savefig("2_1.png");

p1 = histogram(sea_level, bins=10000, label=false, title="Sea-level [mm]", titlefontsize=8);
p2 = histogram(sea_level_inch, bins=10000, label=false, title="Sea-level [inch]", titlefontsize=8);
plot(p1, p2, layout=(2, 1), dpi=500);
savefig("2_2.png");

p1 = histogram(diff(sea_level), bins=10000, label=false, title="Sea-level diff [mm]", titlefontsize=8, xlim=(-500, 500))

p2 = histogram(diff(sea_level_inch ./ 16.0), bins=10000, label=false, title="Sea-level diff [1/16 inch]", titlefontsize=8, xlim=(-2, 2))
plot(p1, p2, layout=(2, 1), dpi=500)
savefig("2_2.png");


s = 100000
bins = 10000
p1 = histogram(diff(first(sea_level_inch, s)), bins=bins, label=false, title="Starting sea-level diff [inch]", titlefontsize=8,
    xlim=(-25, 25));
p2 = histogram(diff(last(sea_level_inch, s)), bins=bins, label=false, title="Ending sea-level diff [inch]", titlefontsize=8,
    xlim=(-25, 25));
plot(p1, p2, layout=(2, 1), dpi=500);
savefig("2_3.png");

p1 = histogram(diff(first(sea_level, s)), bins=bins, label=false, title="Starting sea-level diff [mm]", titlefontsize=8,
    xlim=(-500, 500));
p2 = histogram(diff(last(sea_level, s)), bins=bins, label=false, title="Ending sea-level diff [mm]", titlefontsize=8,
    xlim=(-500, 500));
plot(p1, p2, layout=(2, 1), dpi=500)
savefig("2_3.png");

close(nc)
