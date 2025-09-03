# %%
using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv");
plot_profile(d)
# savefig("1.png")

