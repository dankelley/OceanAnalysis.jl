using GMT, Plots
R = [-68, -59, 42, 47.5]
C = [0.5 * (R[1] + R[2]), 0.5 * (R[3] + R[4])]
P = :aea
p = [40 50]
coast(region=R, proj=(name=P, center=C, parallels=p), figsize=10)
text!(text="Nova Scotia", x=-62.9, y=45.3, font=10, angle=22, show=1)
#savefig="map_01.png")
