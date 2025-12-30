using FileIO, JLD2, Plots
d = FileIO.load("heatmap_question.jld2");
x = d["x"];
y = d["y"];
z = d["z"];
A = heatmap(x, y, z, color=:turbo, yflip=true) # what I want (full-scale)
xlim = xlims()
ylim = ylims()
plot!(collect(xlim), repeat([1000.0], 2), label=false, color=:black, xlim=xlim, ylim=ylim)
plot!(collect(xlim), repeat([ylim[2] - 1000.0], 2), label=false, color=:black, xlim=xlim, ylim=ylim)
B = heatmap(x, y, z, color=:turbo, ylim=(0, 1000), yflip=true) # OK but I want flipped
C = heatmap(x, y, z, color=:turbo, ylim=ylim[2] .- [1000, 0], yflip=true) # OK but I want flipped
l = @layout[A; B; C]
plot(A, B, C, layout=l)
savefig("heatmap_question.png")
