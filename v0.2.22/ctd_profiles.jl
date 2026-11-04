# Read and plot a built-in CTD file
using OceanAnalysis, Printf
using GLMakie # or CairoMakie
filename = joinpath(pkgdir(OceanAnalysis), "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
fig = Figure()
plot_profile!(fig[1, 1], ctd; which="CT");
plot_profile!(fig[1, 2], ctd; which="SA");
plot_profile!(fig[1, 3], ctd; which="sigma0");
save("ctd_profiles.png", fig, px_per_unit=2)
