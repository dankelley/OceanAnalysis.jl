using CairoMakie, GeoMakie

# Define region and projection
region = (-100, -30, 45, 85)
proj = "+proj=lcc +lon_0=-65 +lat_1=40 +lat_2=50"

# 1️⃣ Apply theme *before* creating the figure
set_theme!(Theme(fontsize=12, font="Helvetica"))

# 2️⃣ Create figure
fig = Figure(resolution=(1200, 800))

# 3️⃣ Create geographic axis
ax = GeoAxis(fig[1, 1],
    dest=proj,
    limits=region,
    title="Station Map",
    titlesize=18,
    xticklabelsize=12,
    yticklabelsize=12,
    xlabel="Longitude",
    ylabel="Latitude",
)

# 4️⃣ Add coastlines and land
poly!(ax, GeoMakie.land(), color=:gray80)
lines!(ax, GeoMakie.coastlines(), color=:black, linewidth=0.6)

# 5️⃣ Add points and labels
x = [-60.0, -70.0, -80.0]
y = [60.0, 65.0, 70.0]
names = ["A", "B", "C"]

scatter!(ax, x, y, color=:red, markersize=10)
text!(ax, x, y, text=names, offset=(10, 8), align=(:left, :center), fontsize=12)

# 6️⃣ Save and/or display
save("lab_sea.png", fig)
fig

