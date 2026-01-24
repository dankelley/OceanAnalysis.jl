using OceanAnalysis, Plots
f = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
e = read_echosounder(f)#; debug=1)
heatmap(log10.(e.data["a"]), c=:turbo)
println("FIXME: why need to transpose?")
println("FIXME: next: save time and distance")
savefig("echosounder_02.png")

