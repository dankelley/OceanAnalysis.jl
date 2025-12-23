using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
a = read_ctd_cnv(f, add_teos=false);
b = read_ctd_cnv(f, add_teos=false);
c = read_ctd_cnv(f, add_teos=false);
b.data.salinity = 0.5 .+ b.data.salinity;
c.data.salinity = 1.0 .+ c.data.salinity;
s = Vector{Ctd}(undef, 3);
s[1] = a;
s[2] = b;
s[3] = c;
S = [s[1].data.salinity s[2].data.salinity s[3].data.salinity]
contour(1:3, 1:181, S, yflip=true)
savefig("section_01.pdf")

