using OceanAnalysis, DataFrames, Test

pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
a = read_argo(f)
a2 = drop_qc(a)

@test ncol(a.data) == 15
@test ncol(a2.data) == 9


