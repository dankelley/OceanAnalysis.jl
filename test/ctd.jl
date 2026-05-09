using OceanAnalysis, DataFrames, Test
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);

@testset "mixed-layer depth" begin
    MLDindex = MLD_CF(ctd)
    @test MLDindex == 13
    MLDpressure = ctd["pressure"][MLDindex]
    @test MLDpressure == 4.292
end

@testset "read_ctd_cnv()" begin
    @test ctd.metadata["longitude"] ≈ -63.643883333333335 atol = 1e-13
    @test ctd.metadata["latitude"] ≈ 44.684266666666666 atol = 1e-13
    @test 42 == length(ctd.metadata["header"])
end



