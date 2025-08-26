# %%
using OceanAnalysis, Plots, Measures, GibbsSeaWater

# %%
f(x, y) = sqrt.(x^2 .+ y^2)
xg = -0.5:0.01:0.5
yg = -0.5:0.01:0.5
zg = [f(x, y) for x in xg, y in yg]

gf = collect(minimum(zg):0.05:maximum(zg))
gc = collect(minimum(zg):0.10:maximum(zg))
gf_trimmed = collect(setdiff(gf, gc))

p1 = contour(xg, yg, zg, linecolor=:red, cbar=false, contour_labels=false, levels=gf_trimmed,
    margin=1cm, framestyle=:box)
contour!(xg, yg, zg, linecolor=:blue, cbar=false, contour_labels=true, levels=gc)
RHS = 0.5
Y = 0.33
annotate!(RHS * 1.04, Y, text("0.6", :left, 8))
savefig("contour_test_j_1.png")

p2 = contour(xg, yg, zg, margin=1cm, framestyle=:box)
savefig("contour_test_j_2.png")

levels = pretty(zg)
println(levels)
p2 = contour(xg, yg, zg, levels=levels, margin=1cm, framestyle=:box)
savefig("contour_test_j_3.png")



# %%
# Idea for finding margin placements for isopycnal labels
# in a TS diagram.
# https://www.teos-10.org/pubs/gsw/html/gsw_CT_from_rho.html
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

# %%
# check against R
# > gsw_CT_from_rho(1028,35,0)
# [1] -0.50331932769111
diff = abs(gsw_ct_from_rho(1028.0, 35.0, 0.0)[1] - (-0.50331932769111))
#println("julia vs R difference $diff")
if diff > 1e-10 # it is 2.22e-16 on an M4 mac
    error("differs from R-computed value by $diff")
end

