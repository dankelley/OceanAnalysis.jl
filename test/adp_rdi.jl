using Dates, Plots, OceanAnalysis, Test
# The tests are against values from R/oce.
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
adp = read_adp_rdi(file);
# Test some metadata
@test adp["beam_angle"] == 20.0
@test adp["beam_configuration"] == :four_beam_janus
@test adp["convex"] == true
@test adp["data_offsets"] == [18, 77, 142, 816, 1154, 1492]
@test adp["depth_cell_length"] == 0.5
@test adp["direction"] == "up"
@test adp["frequency"] == 300
@test adp["data_types"] == [:velocity, :correlation_magnitude, :echo_intensity, :percent_good]
@test adp["nbeams"] == 4
@test adp["ncells"] == 84
@test adp["nensembles"] == 25
@test adp["version"] == "16.28"
# Test some data
@test size(adp["velocity"]) == (25, 84, 4)
@test size(adp["correlation_magnitude"]) == (25, 84, 4)
@test size(adp["echo_intensity"]) == (25, 84, 4)
@test size(adp["percent_good"]) == (25, 84, 4)
@test adp["time"][1:3] == DateTime.(["2008-06-26T00:00:00", "2008-06-26T01:00:00", "2008-06-26T02:00:00"], "y-m-dTH:M:S")
@test adp["sound_speed"][1:3] == [1467; 1466; 1466]
@test adp["heading"][1:3] ≈ [294.98; 294.90; 294.87] atol = 0.01
@test adp["pitch"][1:3] ≈ [-2.932802; -2.932802; -2.932802] atol = 0.000001
@test adp["roll"][1:3] ≈ [5.36; 5.36; 5.36]
@test adp["velocity"][1, 1, :] ≈ [0.112; -0.094; -0.018; 0.039] atol = 0.001
@test adp["velocity"][2, 1, :] ≈ [0.053; -0.055; -0.034; 0.021] atol = 0.001
@test adp["correlation_magnitude"][1, 1, :] == [0x6c; 0x6e; 0x72; 0x7a]
@test adp["correlation_magnitude"][2, 1, :] == [0x6a; 0x70; 0x70; 0x71]
@test adp["echo_intensity"][1, 1, :] == [0x99; 0xa0; 0xa0; 0xa0]
@test adp.data["percent_good"][1, 1, :] == [0x64; 0x64; 0x64; 0x64]
@test adp["distance"] == range(2.21, step=0.5, length=84)
# Transformation matrix
tm_expected = [1.4619022 -1.4619022 0.0000000 0.0000000;
    0.0000000 0.0000000 -1.4619022 1.4619022;
    0.2660444 0.2660444 0.2660444 0.2660444;
    1.0337210 1.0337210 -1.0337210 -1.0337210]
@test adp["transformation_matrix"] ≈ tm_expected atol = 1e-5
# Coordinate transformation
adp_xyz = beam_to_xyz(adp);
@test adp_xyz["velocity"][1, 1, :] ≈ [0.301151853; 0.083328425; 0.010375733; -0.003101163] atol = 1e-8
@test adp_xyz["velocity"][2, 1, :] ≈ [0.157885438; 0.080404621; -0.003990667; 0.011370931] atol = 1e-8
@test adp_xyz["velocity"][1, 2, :] ≈ [0.308461364; 0.078942719; 0.009843644; 0.009303489] atol = 1e-8
