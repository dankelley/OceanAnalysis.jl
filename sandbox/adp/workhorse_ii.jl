using OceanAnalysis, Plots, Dates
file = "/Users/kelley/Downloads/rdi_whii600_sample.000"
adp = read_adp_rdi(file; debug=1);
#println("file has $(length(adp["time"])) ensembles, at times, starting with")
#println(first(adp["time"], 5))
#println("data_types: ", adp["data_types"])
#println("data_offsets: ", adp["data_offsets"])
#println(keys(adp.metadata))

t = datetime2unix.(adp["time"]); # seconds
hour = (t .- t[1]) / 3600.0;
fs = 6;
p1 = plot(hour, adp["ISM_mag_x1"], ylab="mag_x1",
    legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs);
p2 = plot(hour, adp["ISM_mag_y1"], ylab="mag_y1",
    legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs);
p3 = plot(hour, adp["ISM_mag_z1"], ylab="mag_z1",
    legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs);
p4 = plot(hour, adp["ISM_acc_x1"], ylab="acc_x1",
    legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs);
p5 = plot(hour, adp["ISM_acc_y1"], ylab="acc_y1",
    legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs);
p6 = plot(hour, adp["ISM_acc_z1"], ylab="acc_z1",
    legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs);
l = @layout[p1 p4; p2 p5; p3 p6]
plot(p1, p4, p2, p5, p3, p6, layout=l, size=(1000, 800), dpi=300)
savefig("workhorse_II.png")

