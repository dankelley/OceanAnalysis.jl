# North Atlantic Sea Surface Temperature
using OceanAnalysis, Plots, Dates
f = get_amsr("2025-09-07");
a = read_amsr(f, "SST");
plot_amsr(a, xlims=(290.0, 340.0), ylims=(30.0, 60.0),
    draw_contours=0.0:2.5:30.0, clim=(0, 30), debug=1)
savefig("amsr.png")

