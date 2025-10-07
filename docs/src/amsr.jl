# North Atlantic Sea Surface Temperature
using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc"
a = read_amsr(f, "SST");
plot_amsr(a, xlims=(290.0, 340.0), ylims=(30.0, 60.0), color=:turbo,
    levels=0.0:2.5:30.0, clim=(0, 30))
savefig("amsr.png")
