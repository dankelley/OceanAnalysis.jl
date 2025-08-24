using OceanAnalysis
using Test

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
    @test T90_from_T48([1.0; 2.0]) ≈ [0.9993245621051; 1.9986579220987] atol = 1e-14
end

@testset "T90_from_T68()" begin
    @test T90_from_T68(1.0) ≈ 0.9997600575862 atol = 1e-13
    @test T90_from_T68([1.0; 2.0]) ≈ [0.9997600575862; 1.9995201151724] atol = 1e-13
end

