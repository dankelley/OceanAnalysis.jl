# %%
using OceanAnalysis, Plots, Dates

# %% Read the data
f = get_amsr_file(Date("2025-08-12"), debug=1)
if !@isdefined a
    println("reading 'a'")
    a = read_amsr(f, debug=1)
else
    println("'a' already exists")
end


# This was I think the day we found the eddy:
# Date: 12/08/2025 Lat: 59.200948 Lon: -55.027402
#
# Then here are the locations when we did 5 CTDs in one day crossing the eddy:
# Date: 18/08/2025 Lat: 58.958121 Lon: -55.410594 
# Date: 18/08/2025 Lat: 58.886678 Lon: -55.288322
# Date: 18/08/2025 Lat: 58.884 Lon: -55.343
# Date: 18/08/2025 Lat: 58.916034 Lon: -55.246876
# Date: 18/08/2025 Lat: 58.937891 Lon: -55.175971
lats = [58.958121; 58.886678; 58.884; 58.916034; 58.937891]
lons = 360.0 .+ [-55.410594; -55.288322; -55.343; -55.246876; -55.175971]

lat0 = 59.200948
lon0 = -55.027402 + 360.0 # add 360 to get in deg E

asp = 1.0 / cos(lat0 * pi / 180.)
span = 5.0 # degrees of span
# OK: span 25 10 8 5?
span = 5 # degrees of span
xlims = [lon0 - asp * span; lon0 + asp * span]
ylims = [lat0 - span; lat0 + span]
println("xlims: ", xlims)
println("ylims: ", ylims)


# %%
println("TESTING")
alon = a.metadata["longitude"];
alat = a.metadata["latitude"];
lonOK = xlims[1] .< alon .< xlims[2];
latOK = ylims[1] .< alat .< ylims[2];

# %%
metadata = Dict()
metadata["longitude"] = a.metadata["longitude"][lonOK];
metadata["latitude"] = a.metadata["latitude"][latOK];
metadata["field"] = "SST"
data = a.data[latOK, lonOK]
b = Amsr(metadata, data)

# %%
GC.gc()

# %%
h = false
if h
    println("TEST: heatmap")
    p = heatmap(a.metadata["longitude"],
        a.metadata["latitude"],
        a.data, color=:turbo, xlims=xlims, ylims=ylims, aspect_ratio=asp)
else
    println("TEST: plot_amsr")
    p = plot_amsr(b, color=:turbo, xlims=xlims, ylims=ylims, levels=0,
        clim=(7, 9), debug=1)
end
#dpi=300, size=(600, 600), debug=1)
#plot!(p, xlims, [lat; lat], color=:magenta, legend=false)
#plot!(p, [lon; lon], ylims, color=:magenta, legend=false)
scatter!(p, [lon0], [lat0], marker=:cross, color=:black)
scatter!(p, lons, lats, marker=:plus, color=:black)
savefig(p, "eb_02_span_$(span).png")
