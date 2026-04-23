using OceanAnalysis, DataFrames, Test

pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
c = read_argo(f) |> as_ctd
c2 = drop_qc(c)

@test ncol(c.data) == 15
@test ncol(c2.data) == 9


