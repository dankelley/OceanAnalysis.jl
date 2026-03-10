using OceanAnalysis, Plots
d = read_ctd_cnv("data/ctd.cnv"; debug=1);
plot_TS(d)
savefig("0_cnv.png")

