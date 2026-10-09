using OceanAnalysis
using GLMakie # or CairoMakie
file = joinpath(pkgdir(OceanAnalysis), "data", "adp_rdi.000")
beam = read_adp_rdi(file);
xyz = beam_to_xyz(beam);
enu = xyz_to_enu(xyz, declination=-18.1); # decl for local region

# 1. Scatterplot of u vs v
fig = plot_adp(enu; which=:uv, title="uv", markersize=2)
save("adp_rdi_uv.png", fig, px_per_unit=2)

# 1. Heatmap of u, v and w
KW = (colorrange=(-1.5, 1.5),) # note the comma
fig = Figure()
plot_adp!(fig[1, 1], enu; which=:velocity1, title="Eastward velocity [m/s]", KW...)
plot_adp!(fig[2, 1], enu; which=:velocity2, title="Northward velocity [m/s]", KW...)
plot_adp!(fig[3, 1], enu; which=:velocity3, title="Upward velocity [m/s]", KW...)
save("adp_rdi_velocity.png", fig, px_per_unit=2)

