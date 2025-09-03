# %%
using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv");
p1 = plot_profile(d, debug=0)
p2 = plot_profile(d, "temperature", debug=0)
plot(p1, p2)
# savefig("1.png")

