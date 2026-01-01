using NCDatasets, Plots, Downloads, CSV, DataFrames, Dates

url = "https://uhslc.soest.hawaii.edu/data/csv/rqds/atlantic/hourly/h275a.csv"
file = replace(url, r"^.*/" => "")
if !isfile(file)
    println("Downloading $file from $url")
    Downloads.download(url, file)
else
    println("Using cached file $file")
end
# File starts
# 1895,10,15,17,650
# 1895,10,15,18,960
d = CSV.read(file, DataFrame, header=["year", "month", "day", "hour", "mm"]);
time = DateTime.(d.year, d.month, d.day, d.hour);
sea_level = d.mm;
ok = .!ismissing.(sea_level);
time = time[ok];
sea_level = sea_level[ok];
bad_code = extrema(sea_level)[1] # (-32767, 2835)
ok = sea_level .!= bad_code;
time = time[ok];
sea_level = sea_level[ok];

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

#savefig("0.pdf")
savefig("0.png");
