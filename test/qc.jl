using OceanAnalysis, DataFrames, Test

# drop_qc()

pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
a = read_argo(f)
a2 = drop_qc(a)

@test ncol(a.data) == 15
@test ncol(a2.data) == 9


# drop_qc()

a = read_argo(f);
a2 = handle_qc(a, retain="1", debug=1);

@test !any(isnan.(a2.data.temperature))
@test !any(isnan.(a2.data.pressure))
@test all(isnan.(a2.data.salinity))
@test all(isnan.(a2.data.salinity_adjusted))

c = as_ctd(a);
c2 = handle_qc(c, debug=1);
@test !any(isnan.(c2.data.temperature))
@test !any(isnan.(c2.data.pressure))
@test all(isnan.(c2.data.salinity))
@test all(isnan.(c2.data.salinity_adjusted))


