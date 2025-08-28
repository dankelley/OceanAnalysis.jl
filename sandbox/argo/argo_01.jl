# %%
using OceanAnalysis, Plots
# D6902967_095.nc cased problems until 'missing' was tested for in read_argo()
f = "/Users/kelley/data/argo/D6902967_095.nc"
d = read_argo(f, debug=1)
println("$f: $(length(d.data.pressure)) levels on $(d.metadata["time"]) at $(round(d.metadata["latitude"], digits=4))N, $(round(d.metadata["longitude"], digits=4))E")
#println(d.data.pressure)
println(d.data)









# %%

p1 = plot_profile(d, "CT")
p2 = plot_profile(d, "SA")
p3 = plot_TS(d)
plot(p1, p2, p3, layout=(1, 3), size=(800, 800))
savefig("argo_01.png")

