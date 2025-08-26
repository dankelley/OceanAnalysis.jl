using Plots

# Example data
x = y = range(-2, 2, length=50)
z = x .* y' # Example function to create contour data

# Create the contour plot
# `contour` returns a `Contour.Contourf` object (which is `CS`)
# and a handle `h`.
CS = contour(x, y, z)

# Define manual locations for labels
manual_locations = [(-1.5, -1.4), (0, 0.5), (1.7, 1.2)] # List of (x, y) coordinates

# Add labels at the specified manual locations
clabel(CS, h, manual=manual_locations, fontsize=8)
savefig("contour_manual_label.png")
