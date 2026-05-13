# Illustrate QC processing of hydrographic data
using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "D4901076_139.nc")
argo = read_argo(f);
ctd = as_ctd(argo);
ctd_clean = handle_qc(ctd);

ul = plot_profile(ctd; which="salinity", dpi=200, fontsize=6)
badS = ctd["salinity_qc"] .!= '1'
scatter!(ctd["salinity"][badS], ctd["pressure"][badS], color=:red, markersize=2)

ur = plot_profile(ctd; which="temperature", dpi=200, fontsize=6)
badT = ctd["temperature_qc"] .!= '1'
scatter!(ctd["temperature"][badT], ctd["pressure"][badT], color=:red, markersize=2)

ll = plot_TS(ctd, fontsize=6)
bad = badS .| badT
scatter!(ctd["SA"][bad], ctd["CT"][bad], color=:red, markersize=2)

lr = plot_TS(ctd_clean, fontsize=6)

plot(ul, ur, ll, lr, layout=(2, 2))
savefig("argo_qc.png")

