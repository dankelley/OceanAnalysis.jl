# The tests are against values from R/oce.
using OceanAnalysis, DataFrames, CSV, Test

file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "wind.csv");
d = CSV.read(file, DataFrame);
res = interpolate_barnes(d.x, d.y, d.z; xg=[5.0], yg=[5.0], xr=1.0, yr=1.0, gamma=0.5, iterations=2);
@test res["zg"][1, 1] ≈ 26.9240176162343 atol = 1.0e-8
