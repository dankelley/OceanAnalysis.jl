using GMT, Plots
R = [-63 - 42 / 60, -63 - 25 / 60, 44 + 33 / 60, 44 + 44 / 60]
C = [0.5 * (R[1] + R[2]), 0.5 * (R[3] + R[4])]
P = :aea
p = [44 48]
P = coast(region=R, proj=(name=P, center=C, parallels=p), figsize=10)
text!(text="B.B.", x=-63 - 38 / 60, y=44 + 41.5 / 60, angle=-47, font=8, show=1, savefig="nova_scotia.png")
