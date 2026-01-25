using OceanAnalysis, Plots
f = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
e = read_echosounder(f);#; debug=1);

nrow, ncol = size(e.data["a"])
# FIXME: define metadata["time"], then use it in next plot line
heatmap(e["time"], e["range"], log10.(e.data["a"]), yflip=true)
savefig("echosounder_02.png")

time = emetadata["time"]
println(first(time, 6))
println(last(time, 6))
