# %%
using OceanAnalysis, Plots
d = read_ctd_cnv("data/ctd.cnv");
println(first(N2(d), 3))

# %%
p1 = plot_profile(d, debug=0)
p2 = plot_profile(d, which="temperature", debug=0)
p3 = plot_profile(d, which="SA", debug=0)
p4 = plot_profile(d, which="salinity", debug=0)
plot(p1, p2, p3, p4, layout=(2, 2))
plot_profile(d, which="scan")

# %%
plot_profile(d, which="N2")
# savefig("1.png")

# %%
plot_TS(d)
