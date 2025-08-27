using OceanAnalysis, Plots
f = "/Users/kelley/Dropbox/oce-working-notes/cnv/dsbe19plus_01906749_2014_09_01_0002.cnv"
d = read_ctd_cnv(f, debug=1)
plot_TS(d)
savefig("a_j.png")

