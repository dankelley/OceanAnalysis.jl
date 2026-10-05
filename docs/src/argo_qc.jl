# Illustrate QC processing of hydrographic data
using OceanAnalysis
using GLMakie # or CairoMakie
f = joinpath(pkgdir(OceanAnalysis), "data", "D4901076_139.nc")
ctd = f |> read_argo |> as_ctd
summarize(ctd)
ctd_clean = handle_qc(ctd);
summarize(ctd_clean)

fig = Figure() # will fill with 4 panels
fs = 11 # larger font than default

plot_profile!(fig[1, 1], ctd; which="salinity", fontsize=fs)
badS = ctd["salinity_qc"] .!= '1';
scatter!(ctd["salinity"][badS], ctd["pressure"][badS], color=:red, markersize=14, marker=:xcross)

plot_profile!(fig[1, 2], ctd; which="temperature", fontsize=fs)
badT = ctd["temperature_qc"] .!= '1';
scatter!(ctd["temperature"][badT], ctd["pressure"][badT], color=:red, markersize=14, marker=:xcross)

plot_TS!(fig[2, 1], ctd, fontsize=fs)
bad = badS .| badT;
scatter!(ctd["SA"][bad], ctd["CT"][bad], color=:red, markersize=14, marker=:xcross)

plot_TS!(fig[2, 2], ctd_clean, fontsize=fs)

save("argo_qc.png", fig, px_per_unit=2)

