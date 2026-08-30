using OceanAnalysis, Test, Dates

@testset "magnetic field compared with R/oce" begin
    time = 2026.0
    longitude = -63.0
    latitude = 45.0
    altitude = 0.0
    declination, inclination, intensity = magnetic_field(time, longitude, latitude, altitude)
    # Comparison with R:
    #   library(oce)
    #   oce::magneticField(time=2026.0, longitude=-63.0, latitude=45.0)
    # yields
    #   declination -16.32922, inclination 66.44525, intensity 51110.98
    @test declination ≈ -16.32922 atol = 0.00001
    @test inclination ≈ 66.44525 atol = 0.00001
    @test intensity ≈ 51110.98 atol = 0.01
end
