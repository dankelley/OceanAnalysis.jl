# Read and plot a built-in Argo file
using OceanAnalysis, Dates, Measures, Printf
using GLMakie # or CairoMakie

# Get data
ctd = joinpath(pkgdir(OceanAnalysis), "data", "D4902911_095.nc") |>
      read_argo |>
      as_ctd;

# Non-mutating example (single panel)
fig = plot_profile(ctd; which="CT")
save("argo_profile_1.png", fig, px_per_unit=2)

# Mutating example (multiple panels)
fig = Figure()
plot_profile!(fig[1, 1], ctd; which="SA");
plot_profile!(fig[1, 2], ctd; which="sigma0");
plot_TS!(fig[1, 3], ctd);
save("argo_profile_2.png", fig, px_per_unit=2)

