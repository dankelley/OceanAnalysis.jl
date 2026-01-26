using Dates, Plots, OceanAnalysis, Test
# The tests are against values from R/oce.
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
beam = read_adp_rdi(file);
xyz = beam_to_xyz(beam);
enu = xyz_to_enu(xyz);

# Test some metadata
@test beam["beam_angle"] == 20.0
@test beam["beam_configuration"] == :four_beam_janus
@test beam["convex"] == true
@test beam["data_offsets"] == [18, 77, 142, 816, 1154, 1492]
@test beam["depth_cell_length"] == 0.5
@test beam["direction"] == :up
@test beam["frequency"] == 300
@test beam["data_types"] == [:velocity, :correlation_magnitude, :echo_intensity, :percent_good]
@test beam["nbeams"] == 4
@test beam["ncells"] == 84
@test beam["nensembles"] == 25
@test beam["version"] == "16.28"
# Test some data
@test size(beam["velocity"]) == (25, 84, 4)
@test size(beam["correlation_magnitude"]) == (25, 84, 4)
@test size(beam["echo_intensity"]) == (25, 84, 4)
@test size(beam["percent_good"]) == (25, 84, 4)
@test beam["time"][1:3] == DateTime.(["2008-06-26T00:00:00", "2008-06-26T01:00:00", "2008-06-26T02:00:00"], "y-m-dTH:M:S")
@test beam["sound_speed"][1:3] == [1467; 1466; 1466]
@test beam["heading"][1:3] ≈ [294.98; 294.90; 294.87] atol = 0.01
@test beam["pitch"][1:3] ≈ [-2.932802; -2.932802; -2.932802] atol = 0.000001
@test beam["roll"][1:3] ≈ [5.36; 5.36; 5.36]
@test beam["velocity"][1, 1, :] ≈ [0.112; -0.094; -0.018; 0.039] atol = 0.001
@test beam["velocity"][2, 1, :] ≈ [0.053; -0.055; -0.034; 0.021] atol = 0.001
@test beam["correlation_magnitude"][1, 1, :] == [0x6c; 0x6e; 0x72; 0x7a]
@test beam["correlation_magnitude"][2, 1, :] == [0x6a; 0x70; 0x70; 0x71]
@test beam["echo_intensity"][1, 1, :] == [0x99; 0xa0; 0xa0; 0xa0]
@test beam.data["percent_good"][1, 1, :] == [0x64; 0x64; 0x64; 0x64]
@test beam["distance"] == range(2.21, step=0.5, length=84)
# Transformation matrix
tm_expected = [1.4619022 -1.4619022 0.0000000 0.0000000;
    0.0000000 0.0000000 -1.4619022 1.4619022;
    0.2660444 0.2660444 0.2660444 0.2660444;
    1.0337210 1.0337210 -1.0337210 -1.0337210]
@test beam["transformation_matrix"] ≈ tm_expected atol = 1e-5
# Coordinate transformation (tested against R, on data in ../data/adp_rdi.000)
@test xyz["velocity"][1, 1, :] ≈ [0.301151853; 0.083328425; 0.010375733; -0.003101163] atol = 1e-8
@test xyz["velocity"][2, 1, :] ≈ [0.157885438; 0.080404621; -0.003990667; 0.011370931] atol = 1e-8
@test xyz["velocity"][1, 2, :] ≈ [0.308461364; 0.078942719; 0.009843644; 0.009303489] atol = 1e-8

@test enu["velocity"][1, 1, :] ≈ [-0.203290360; -0.237137325; 0.013514422; -0.003101163] atol = 1e-8
@test enu["velocity"][1, 2, :] ≈ [-0.202428690; -0.245512510; 0.014949795; 0.009303489] atol = 1e-8
@test enu["velocity"][2, 1, :] ≈ [-0.13973166; -0.10803253; 0.01458341; 0.01137093] atol = 1e-8
@test enu["velocity"][2, 2, :] ≈ [-0.14124715; -0.12495307; 0.01664734; 0.02274186] atol = 1e-8
