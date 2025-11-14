using CairoMakie, GeoMakie

# Apply font + general style before figure creation
set_theme!(Theme(fontsize=12, font="Helvetica"))

# Define region and projection
region = (-100, -30, 45, 85)
proj = "+proj=lcc +lon_0=-65 +lat_1=40 +lat_2=50"

# ✅ Use `size=` instead of `resolution=`
fig = Figure(size=(1200, 800))

# Create geographic axis
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
rect!(ax, -180, -90, 360, 180, color=:white)   # covers entire map area

# Draw land and coastlines
poly!(ax, GeoMakie.land(), color=:gray80)
lines!(ax, GeoMakie.coastlines(), color=:black, linewidth=0.6)

# Add points and labels
x = [-60.0, -70.0, -80.0]
y = [60.0, 65.0, 70.0]
names = ["A", "B", "C"]

scatter!(ax, x, y, color=:red, markersize=10)
text!(ax, x, y, text=names, offset=(10, 8), align=(:left, :center), fontsize=12)

# Save and display
save("lab_sea.png", fig)
fig

