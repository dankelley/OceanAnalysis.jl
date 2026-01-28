using OceanAnalysis, Test, Dates

# My macOS 64-bit M4 machine likes tests to 14 digits but has problems
# with 15 digits.  I set some test values from R/oce, printing with 15 digits,
# but maybe R and Julia differ on roudning at the last digit, or something.
# Basically, even 10 digits is fine in practical terms, as we are mostly
# looking for gross coding errors.


@testset "SA() handles NaN values well" begin
    SP = [34.0, NaN, 34.2, 34.3, 34.4, 34.5]
    p = [10.0, 11.0, NaN, 13.0, 14.0, 15.0]
    lon = [-30.0, -30.0, -30.0, NaN, -30.0, -30.0]
    lat = [30.0, 30.0, 30.0, 30.0, NaN, 30.0]
    @test isnan.(SA.(SP, p, lon, lat)) == [0, 1, 1, 1, 1, 0]
end

@testset "CT() handles NaN values well" begin
    SA_ = [34.0, NaN, 34.2, 34.3, 34.4]
    T = [10.0, 11.0, NaN, 13.0, 14.0]
    p = [10.0, 11.0, 12.0, NaN, 14.0]
    @test isnan.(CT.(SA_, T, p)) == [0, 1, 1, 1, 0]
end

@testset "coordinate_from_string()" begin
    @test coordinate_from_string("1.5") == 1.5
    @test coordinate_from_string("1.5n") == 1.5
    @test coordinate_from_string("n1.5") == 1.5
    @test coordinate_from_string("N1.5") == 1.5
    @test coordinate_from_string("1 30") == 1.5
    @test coordinate_from_string("1.5S") == -1.5
    @test coordinate_from_string("s1 30") == -1.5
    @test coordinate_from_string("27* 14.072 N") ≈ (27.0 + 14.072 / 60) atol = 1e-5
    @test coordinate_from_string("111* 31.440 W") ≈ -(111 + 31.440 / 60) atol = 1e-5
end

@testset "conductivity and salinity" begin
    @test salinity_from_conductivity(34.5487, 28.7856, 10.0) ≈ 20.009869599086951 atol = 1e-10
end

@testset "pressure, depth and z" begin
    @test z_from_pressure(10.0) ≈ -9.91860027692906 atol = 1e-14
    @test pressure_from_z(-9.918600276929064) ≈ 10.0 atol = 1e-14
    @test depth_from_pressure(10.0) ≈ 9.91860027692906 atol = 1e-14
    @test pressure_from_depth(9.918600276929064) ≈ 10.0 atol = 1e-14
end

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

@testset "read_argo()" begin
    filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "D4902911_095.nc")
    argo = read_argo(filename, add_teos=false)
    @test argo.metadata["longitude"] ≈ -66.38298 atol = 1e-13
    @test argo.metadata["latitude"] ≈ 40.45216 atol = 1e-13
    @test argo.metadata["time"] == Dates.DateTime("2019-10-14T23:43:44.003")
    @test 1014 == length(argo.data.pressure)
    @test first(argo.data.salinity) ≈ 34.913 atol = 0.0001
    @test first(argo.data.temperature) ≈ 19.513 atol = 0.0001
    @test first(argo.data.pressure) ≈ 0.48 atol = 0.0001
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

@testset "geod_distance() agrees with oce/R" begin
    d = geod_distance(0.0, 45.0, 40.0, 46.0)
    @test d ≈ 3095.1741526503 atol = 1e-11
end

@testset "adp_rdi agrees with oce/R" begin
    include("adp_rdi.jl")
end
