using OceanAnalysis
using GLMakie # or CairoMakie
file = get_amsr()
sst = read_amsr(file, "SST");

title = "SST " * sst["time_coverage_start"][1:10] *
        " to " * sst["time_coverage_end"][1:10] *
        " (with 1-km isobath shown)"
fig = plot_amsr(sst; limits=(275.0, 350.0, 20.0, 65.0), title=title)

# Add 1-km isobath. Note the transposition of the data (needed for Makie) and
# the redrawing, required because AMSR has 0<=lon<=360 whereas topography
# has -180<=lon<=180.
tf = get_topography()
t = read_topography(tf);
contour!(t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
contour!(360.0 .+ t["longitude"], t["latitude"], t.data',
    levels=[-1000.0], color=:black, linewidth=1)
save("amsr.png", fig, px_per_unit=2)
