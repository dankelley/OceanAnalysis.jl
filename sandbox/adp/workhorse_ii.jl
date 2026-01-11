using OceanAnalysis, Plots, Dates
file = "/Users/kelley/Downloads/rdi_whii600_sample.000"
#file = "/Users/kelley/adp_rdi.000"
# 10Mb file (4063 ensembles) took 1.8s for first run, 0.96s for second run
@time adp = read_adp_rdi(file); # 0.878s 10K file
@time adp = read_adp_rdi(file; debug=1); # 0.000861 10K file
@time adp = read_adp_rdi(file); # 0.000861 10K file
@time adp = read_adp_rdi(file); # 0.000861 10K file

t = datetime2unix.(adp["time"]); # seconds
hour = (t .- t[1]) / 3600.0;
fs = 10;
if "ISM_mag" in keys(adp.data)
    p1 = plot(hour, adp["ISM_mag"][:, 1], xlab="Hour since power-on", ylab="mag x",
        legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs)
    p2 = plot(hour, adp["ISM_mag"][:, 2], xlab="Hour since power-on", ylab="mag y",
        legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs)
    p3 = plot(hour, adp["ISM_mag"][:, 3], xlab="Hour since power-on", ylab="mag z",
        legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs)
    p4 = plot(hour, adp["ISM_acc"][:, 1], xlab="Hour since power-on", ylab="acc x [milli-gravity]",
        legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs)
    p5 = plot(hour, adp["ISM_acc"][:, 2], xlab="Hour since power-on", ylab="acc y [milli-gravity]",
        legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs)
    p6 = plot(hour, adp["ISM_acc"][:, 3], xlab="Hour since power-on", ylab="acc z [milli-gravity]",
        legend=false, seriestype=:scatter, ms=1, guidefontsize=fs, tickfontsize=fs)
    l = @layout[p1 p4; p2 p5; p3 p6]
    plot(p1, p4, p2, p5, p3, p6, layout=l, size=(1000, 800), dpi=300)
    savefig("workhorse_II_jl.png")
end

display(adp["velocity"][1, 1:3, :])
display(adp["echo_intensity"][1, 1:3, :])
display(adp["correlation_magnitude"][1, 1:3, :])
display(adp["percent_good"][1, 1:3, :])

