# %%
using OceanAnalysis
d = read_ctd_cnv("data/ctd.cnv");
plot_profile(d, debug=1)
# savefig("1.png")

