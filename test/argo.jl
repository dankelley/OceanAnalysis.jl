using OceanAnalysis, DataFrames, Test
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "D4902911_095.nc")
argo = read_argo(filename)

@testset "read_argo()" begin
    @test argo.metadata["longitude"] ≈ -66.38298 atol = 1e-13
    @test argo.metadata["latitude"] ≈ 40.45216 atol = 1e-13
    @test argo.metadata["time"] == Dates.DateTime("2019-10-14T23:43:44.003")
    @test 1014 == length(argo.data.pressure)
    @test first(argo.data.salinity) ≈ 34.913 atol = 0.0001
    @test first(argo.data.temperature) ≈ 19.513 atol = 0.0001
    @test first(argo.data.pressure) ≈ 0.48 atol = 0.0001
end


