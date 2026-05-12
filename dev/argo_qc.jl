using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "D4901076_139.nc")
a = read_argo(f);
b = handle_qc(a);
c = handle_qc(a, action=:delete);
pa = plot_profile(as_ctd(a); which="salinity", dpi=200, fontsize=6)
pb = plot_profile(as_ctd(b); which="salinity", dpi=200, fontsize=6)
pc = plot_profile(as_ctd(c); which="salinity", dpi=200, fontsize=6)
plot(pa, pb, pc, layout=(1, 3))
savefig("argo_qc.png")

