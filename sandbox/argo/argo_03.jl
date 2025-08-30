# add .metadata items: filename, platform, and cycle
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f1 = joinpath(pkgdir, "data", "D4902911_095.nc")
f2 = "/Users/kelley/data/argo/R1902325_038D.nc" # NOTE the "D" in the cycle
using NCDatasets
for f in (f1, f2)
    if isfile(f)
        println("file: $f")
        d = NCDataset(f, "r")
        platform = replace(join(d["PLATFORM_NUMBER"][:, 1]), "missing" => "")
        println("  low-level inference: platform '$platform'")

        cycle = string(d["CYCLE_NUMBER"][1])
        println("  low-level inference: cycle '$cycle'")

        # The above was inserted into OceanAnalysis, as shown below
        d = read_argo(f)
        println("  metadata: $(d.metadata)")
        println("\n")
        plot_TS(d)
        savefig(f * ".png")
    end
end
