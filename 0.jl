using OceanAnalysis, Plots, Statistics
#include("/Users/kelley/git/OceanAnalysis.jl/src/running.jl")
i = 1:100;
x = sin.(2 * pi * i / 50);
xmean = running_mean(x, 3); # 0.12533323356430426 to -4.898587196589413e-16
xmedian = running_median(x, 3);
p1 = scatter(i, x, ylab="x", ms=2, guidefontsize=8, label=false)
p2 = scatter(i, x - xmean, ylab="x - run_mean(x)", ms=2, guidefontsize=8, label=false)
p3 = scatter(i, x - xmedian, ylab="x - run_median(x)", ms=2, guidefontsize=8, label=false)
plot(p1, p2, p3, layout=(3, 1))
savefig("0.pdf")
