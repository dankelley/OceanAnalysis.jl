using CairoMakie, GeoMakie

set_theme!(Theme(fontsize=12, font="Helvetica"))

region = (-100, -30, 45, 85)
proj = "+proj=lcc +lon_0=-65 +lat_1=40 +lat_2=50"

fig = Figure(size=(1200, 800))

ax = GeoAxis(fig[1, 1];
    dest=proj,
    limits=region,
    title="Station Map",
    titlesize=18,
    xticklabelsize=12,
    yticklabelsize=12,
    xlabel="Longitude",
    ylabel="Latitude"
)

# ✅ Fill ocean (background) white
plot!(ax, [-180, -180, 180, 180],
    [-90, 90, 90, -90], color=:white, seriestype=:shape)

# ✅ Fill land gray
poly!(ax, GeoMakie.land(), color=:gray80)

# ✅ Coastlines
lines!(ax, GeoMakie.coastlines(), color=:black, linewidth=0.6)

# Example points
x = [-60.0, -70.0, -80.0]
y = [60.0, 65.0, 70.0]
names = ["A", "B", "C"]
scatter!(ax, x, y, color=:red, markersize=10)
text!(ax, x, y, text=names, offset=(10, 8), align=(:left, :center), fontsize=12)

save("lab_sea.png", fig)
fig

