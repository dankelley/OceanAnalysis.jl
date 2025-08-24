# %%
using Plots

f(x, y) = sin(x) * cos(y)
xs = -π:0.1:π
ys = -π:0.1:π
zs = [f(x, y) for x in xs, y in ys]

contour(xs, ys, zs, linecolor=:gray, cbar=false, contour_labels=false,
    levels=-1:0.1:1)
contour!(xs, ys, zs, linecolor=:black, cbar=false, contour_labels=true,
    levels=-0.5:0.5:0.5)
savefig("contour_test.png")

