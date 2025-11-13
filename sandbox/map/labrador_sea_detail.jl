using GMT#, Plots
gmtset(
    FONT_TITLE="5p,Helvetica-Bold,black",
    FONT_LABEL="5p,Helvetica,black",
    FONT_ANNOT_PRIMARY="5p,Helvetica,black"
)
R = [-60, -45, 46, 54]
C = [0.5 * (R[1] + R[2]), 0.5 * (R[3] + R[4])]
P = :lcc
p = [46 54]
coast(region=R, proj=(name=P, center=C, parallels=p),
    figsize=8, land=:darkgray)
y = [52.18357, 52.21487, 52.24162, 52.26901, 52.29615, 52.32285, 52.34962, 52.40408, 52.45696, 52.5104, 52.56476, 52.61816]
x = [-55.56524, -55.33905, -55.1206, -54.90306, -54.684, -54.46707, -54.24811, -53.81111, -53.37393, -52.93691, -52.49594, -52.05687]
GMT.scatter!(x, y, marker=:cross, markersize=0.10,
    show="/Users/kelley/labrador_sea_detail.png")
#GMT.scatter!(x, y, marker=:plus, show="/Users/kelley/nova_scotia.png")

