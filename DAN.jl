file = "D4902911_095.nc"
if isfile(file)
    using Plots, GibbsSeaWater, OceanAnalysis
    d = readArgo(file, 1) # downloaded from an Argo server
    p1 = plot(getElement(d, "sigma0"), d.pressure, xlab="sigma0", ylab="Pressure [dbar]",
        yflip=true, dpi=500, legend=false)

    s = 0.15 # experiment with this value
    N2val = N2(d, s)
    p2 = plot(1e4 * N2val, d.pressure, xlab="1e4 N^2", ylab="Pressure [dbar]",
        yflip=true, dpi=500, legend=false, title="s=$s", titlefontsize=10)

    plot(p1, p2, layout=(1, 2))
end
