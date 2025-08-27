# %%
using OceanAnalysis, Test
@test z_from_pressure(10.0) ≈ -9.91860027692906 atol = 1e-10
@test pressure_from_z(-9.918600276929064) ≈ 10.0 atol = 1e-10
@test depth_from_pressure(10.0) ≈ 9.91860027692906 atol = 1e-10
@test pressure_from_depth(9.918600276929064) ≈ 10.0 atol = 1e-10
