# Smooth to 1-dbar grid; note that mean(diff(p))=0.24 dbar.
using OceanAnalysis
using GLMakie # or CairoMakie
file = joinpath(pkgdir(OceanAnalysis), "data", "ctd.cnv")
ctd = read_ctd_cnv(file);
p = ctd["pressure"];
y = repeat([1], length(p)); # fake y data, with arbitrary value
SA = ctd["SA"];
dp = 1.0;
pg = range(0.0, maximum(p), step=dp);
g = interpolate_barnes(p, y, SA; xg=pg, xr=dp);
fig = plot_profile(ctd, which="SA", seriestype=:scatter)
lines!(g["zg"][:], g["xg"][:], color=:red, label=false)
save("ctd_smooth.png", fig, px_per_unit=2)

