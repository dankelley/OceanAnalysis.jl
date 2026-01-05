using Dates, Plots, OceanAnalysis, Test

#file = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
adp = read_adp_rdi(file); # 0.6s for 9-profile case

v = adp["velocity"];
tm = adp["transformation_matrix"];
ne = size(v)[1]
V = copy(v)
for i in 1:ne
    V[i, :, :] = v[i, :, :] * tm
end
p = plot(v[:, 1, 4]);
P = plot(V[:, 1, 4]);
plot(p, P, layout=@layout[a; b])
clim = (-1, 1)
color = :RdBu
a = heatmap(v[:, :, 1], clim=clim, c=color);
b = heatmap(V[:, :, 1], clim=clim, c=color);
c = heatmap(v[:, :, 2], clim=clim, c=color);
d = heatmap(V[:, :, 2], clim=clim, c=color);
e = heatmap(v[:, :, 3], clim=clim, c=color);
f = heatmap(V[:, :, 3], clim=clim, c=color);
g = heatmap(v[:, :, 4], clim=clim, c=color);
h = heatmap(V[:, :, 4], clim=clim, c=color);
plot(a, b, layout=@layout[a; b])
plot(c, d, layout=@layout[a; b])
plot(e, f, layout=@layout[a; b])
plot(g, h, layout=@layout[a; b])

A = plot(1:ne, v[:, 1, 1])
B = plot(1:ne, V[:, 1, 1])
plot(A, B, layout=@layout[a; b])

