using OceanAnalysis,Plots
f = "/Users/kelley/Dropbox/oce-working-notes/cnv/d201120_0001.cnv"
d = read_ctd_cnv(f, debug=1)
plot_TS(d)

