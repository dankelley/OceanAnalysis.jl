using OceanAnalysis
using GLMakie
file = joinpath(pkgdir(OceanAnalysis), "data", "adp_rdi.000")
beam = read_adp_rdi(file);
xyz = beam_to_xyz(beam);
enu = xyz_to_enu(xyz, declination=-18.1); # decl for local region

# 1. Scatterplot of u vs v
KW = (fontsize=11, markersize=2)
fig = plot_adp(enu; which=:uv, title="uv", KW...)
save("adp_rdi_uv.png", fig)

# 1. Heatmap of u, v and w
KW = (fontsize=11, colorrange=(-1.5, 1.5))
fig = Figure()
plot_adp!(fig[1, 1], enu; which=:velocity1, title="Eastward velocity [m/s]", KW...)
plot_adp!(fig[2, 1], enu; which=:velocity2, title="Northward velocity [m/s]", KW...)
plot_adp!(fig[3, 1], enu; which=:velocity3, title="Upward velocity [m/s]", KW...)
save("adp_rdi_velocity.png", fig)

