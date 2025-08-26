# %%
# Idea for finding margin placements for isopycnal labels
# https://www.teos-10.org/pubs/gsw/html/gsw_CT_from_rho.html
using OceanAnalysis, Plots, Measures, GibbsSeaWater

# %%
# check against R
# > gsw_CT_from_rho(1028,35,0)
# [1] -0.50331932769111
diff = abs(gsw_ct_from_rho(1028.0, 35.0, 0.0)[1] - (-0.50331932769111))
#println("julia vs R difference $diff")
if diff > 1e-10 # it is 2.22e-16 on an M4 mac
    error("differs from R-computed value by $diff")
end

# %%
# a built-in CTD file
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "ctd.cnv")
ctd = read_ctd_cnv(filename)

# %%
min_rho = minimum(ctd.data.sigma0)
max_rho = maximum(ctd.data.sigma0)
nlevels = 8.0
step = (max_rho - min_rho) / nlevels

# %%
rho_start = floor(0.5 * (2.0 * minimum(ctd.data.sigma0)))
max_rho = 1000.0 .+ floor(1 + 0.5 * (2.0 * maximum(ctd.data.sigma0)))
step_rho = nlevels * floor((max_rho - min_rho) / nlevels)
sigma0_levels = range(min_rho, stop=max_rho, step=step_rho)
print(sigma0_levels)

# %%
plot_TS(ctd, sigma0_levels=sigma0_levels)

# %% compute CT positions for labels on TS plot RHS
maxSA = maximum(ctd.data.SA)
rhos = 1000 .+ sigma0_levels
CT = repeat([0.0], length(rhos))
for i in 1:length(rhos)
    CT[i] = gsw_ct_from_rho(rhos[i], maxSA, 0.0)[1]
end

# %%
ok = CT .< 1e15
rhos = rhos[ok]
CT = CT[ok]
println([rhos, CT])

