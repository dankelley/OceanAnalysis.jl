# %%
using OceanAnalysis, Plots
f = "/Users/kelley/Dropbox/oce-working-notes/cnv/S262-023-CTD.cnv"
d = read_ctd_cnv(f);
n = length(d.data.pressure)
println(names(d.data))
dd = d.data[:, ["pressure", "c0mS/cm", "salinity", "temperature", "SA", "CT", "sigma0", "spiciness0"]]
println(first(dd, 4))
println(last(dd, 4))
if false
    p = d.data.pressure
    bad = sum(p .< 0)
    histogram(p[p.<0],
        title="Have $bad negative pressures, or $(round(100*bad/length(p))) percent of values",
        titlefont=font(10))
    s0 = d.data.sigma0
    plot_TS(d)
end
