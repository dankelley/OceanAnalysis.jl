# %%
using OceanAnalysis, Plots
f = "/Users/kelley/Dropbox/oce-working-notes/cnv/S262-023-CTD.cnv"
d = read_ctd_cnv(f);

# %%
p = d.data.pressure
bad = sum(p .< 0)
histogram(p[p.<0],
    title="Have $bad negative pressures, or $(round(100*bad/length(p))) percent of values",
    titlefont=font(10))
s0 = d.data.sigma0

# %%
extrema(filter(!isnan, s0))

# %%
plot_TS(d, debug=1)

