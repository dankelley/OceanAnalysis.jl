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

# %% compute CT positions for labels on TS plot RHS
maxSA = 35.0
rhos = 1020.0:0.25:1030
CT = repeat([0.0], length(rhos))
for i in 1:length(rhos)
    CT[i] = gsw_ct_from_rho(rhos[i], maxSA, 0.0)[1]
end

# %%
ok = CT .< 1e15
rhos = rhos[ok]
CT = CT[ok]
println([rhos, CT])

