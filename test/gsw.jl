# Test GSW conversions
using GibbsSeaWater, Test
@testset "convert to/from GSW" begin
    T = 10.0
    SP = 35.0
    p = 100.0
    lon = -63.0
    lat = 45.0
    SA = gsw_sa_from_sp(SP, p, lon, lat)
    CT = gsw_ct_from_t(SA, T, p)
    SP2 = gsw_sp_from_sa(SA, p * 0, lon, lat)
    T2 = gsw_t_from_ct(SA, CT, p * 0)
    @test T2 ≈ T rtol = 1e-8
    @test SP2 ≈ SP rtol = 1e-8
end
