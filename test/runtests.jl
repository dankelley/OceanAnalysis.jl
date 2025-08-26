using OceanAnalysis, Test

@testset "coordinate_from_string()" begin
    @test coordinate_from_string("1.5") == 1.5
    @test coordinate_from_string("1.5n") == 1.5
    @test coordinate_from_string("n1.5") == 1.5
    @test coordinate_from_string("N1.5") == 1.5
    @test coordinate_from_string("1 30") == 1.5
    @test coordinate_from_string("1.5S") == -1.5
    @test coordinate_from_string("s1 30") == -1.5
end

# FIXME: how to know how many digits will be best on other machines? This
# is for macos 64 bit; decreasing to 1e-15 makes test fail.  (I printed
# test results with 15 digits in R.)
@testset "T90_from_T48()" begin
    @test T90_from_T48(1.0) ≈ 0.9993245621051 atol = 1e-14
    @test T90_from_T48.([1.0; 2.0]) ≈ [0.9993245621051; 1.9986579220987] atol = 1e-14
end

@testset "T90_from_T68()" begin
    @test T90_from_T68(1.0) ≈ 0.9997600575862 atol = 1e-13
    @test T90_from_T68.([1.0; 2.0]) ≈ [0.9997600575862; 1.9995201151724] atol = 1e-13
end

@testset "read_ctd_cnv()" begin
    filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
    ctd = read_ctd_cnv(filename)
    @test ctd.metadata["longitude"] ≈ -63.643883333333335 atol = 1e-13
    @test ctd.metadata["latitude"] ≈ 44.684266666666666 atol = 1e-13
    @test 42 == length(ctd.metadata["header"])
end

@testset "pretty() tests for consistency with R" begin
    e = 0.0:2.0:16
    p = pretty(1:15)
    @test e == p

    e = 0.0:5.0:15.0
    p = pretty(1:15, 4)
    @test e == p

    e = 0.0:10.0:20.0
    p = pretty(1:20, 2)
    @test e == p

    e = 0.0:2.0:20.0
    p = pretty(1:20, 10)
    @test e == p
end
