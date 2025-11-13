using GMT, Plots
R = [-68, -59, 42, 47.5]
C = [0.5 * (R[1] + R[2]), 0.5 * (R[3] + R[4])]
P = :aea
p = [40 50]
coast(region=R, proj=(name=P, center=C, parallels=p), figsize=10, land=:gray)#, savefig="nova_scotia.png")
x = [-64.5; -64.6]
y = [45.5; 45.6]
GMT.scatter!(x, y, show=true)
#savefig("bark.png")
