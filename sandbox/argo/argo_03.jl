using OceanAnalysis, NCDatasets, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f1 = joinpath(pkgdir, "data", "D4902911_095.nc")
f2 = "/Users/kelley/data/argo/R1902325_038D.nc"
for f in (f1, f2)
    if isfile(f)
        println("file: $f")
        # The above was inserted into OceanAnalysis, as shown below
        d = read_argo(f, debug=0)
        println("  metadata: $(d.metadata)")
        png = replace(f, r".*/(.*).nc$" => s"\1.png")
        plot_TS(d)
        savefig(png)
        println("  plotted to $png")
    end
end
