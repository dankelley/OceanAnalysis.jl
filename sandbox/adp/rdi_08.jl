using Dates, Plots, OceanAnalysis, Test

#file = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
@time adp = read_adp_rdi(file);
@time adp = read_adp_rdi(file);
# Test some metadata
@test adp["beam_angle"] == 20.0
@test adp["data_offsets"] == [18, 77, 142, 816, 1154, 1492]
@test adp["depth_cell_length"] == 0.5
@test adp["direction"] == "up"
@test adp["frequency"] == 300
@test adp["have_data"] == [:velocity, :correlation_magnitude, :echo_intensity, :percent_good]
@test adp["nbeams"] == 4
@test adp["ncells"] == 84
@test adp["nensembles"] == 9
@test adp["version"] == "16.28"
# Test some time-series
@test adp.data["time"] == DateTime.(
    ["2008-06-25 10:00:00", "2008-06-25 10:00:10", "2008-06-25 10:00:20",
        "2008-06-25 10:00:30", "2008-06-25 10:00:40", "2008-06-25 10:00:50",
        "2008-06-25 10:01:00", "2008-06-25 10:01:10", "2008-06-25 10:01:20"],
    "y-m-d H:M:S")
@test adp.data["sound_speed"] == [1497, 1497, 1497, 1497, 1497, 1497, 1497, 1497, 1497]
@test adp.data["heading"] ≈ [278.14, 277.31, 276.78, 276.39, 276.56, 277.07, 277.56, 277.47, 276.98] atol = 0.01
@test adp.data["pitch"] ≈ [1.421236, 1.241172, 1.201080, 1.140976, 1.161010, 1.171018, 1.211098, 1.161001, 1.120942] atol = 0.01
@test adp.data["roll"] ≈ [-2.39, -2.49, -2.43, -2.37, -2.39, -2.39, -2.44, -2.38, -2.35] atol = 0.01

# Test array sizes
@test size(adp.data["velocity"]) == (9, 84, 4)
@test size(adp.data["correlation_magnitude"]) == (9, 84, 4)
@test size(adp.data["echo_intensity"]) == (9, 84, 4)
@test size(adp.data["percent_good"]) == (9, 84, 4)
# Test first 2 cells of first 2 ensembles
@test adp.data["velocity"][1, 1, :] ≈ [0.034; 0.035; 0.005; -0.018] atol = 0.001
@test adp.data["velocity"][1, 2, :] ≈ [0.049, 0.013, 0.081, -0.009] atol = 0.001
@test adp.data["velocity"][2, 1, :] ≈ [0.073, 0.126, 0.07, -0.068] atol = 0.001
@test adp.data["velocity"][2, 2, :] ≈ [-0.012, 0.045, 0.027, -0.027] atol = 0.001
@test adp.data["correlation_magnitude"][1, 1, :] == [0x19, 0x16, 0x19, 0x18]
@test adp.data["correlation_magnitude"][1, 2, :] == [0x17, 0x1e, 0x19, 0x17]
@test adp.data["correlation_magnitude"][2, 1, :] == [0x19, 0x1b, 0x1b, 0x14]
@test adp.data["correlation_magnitude"][2, 2, :] == [0x17, 0x19, 0x19, 0x19]
@test adp.data["echo_intensity"][1, 1, :] == [0x34, 0x2e, 0x30, 0x2d]
@test adp.data["echo_intensity"][1, 2, :] == [0x37, 0x30, 0x33, 0x2f]
@test adp.data["echo_intensity"][2, 1, :] == [0x34, 0x2e, 0x30, 0x2d]
@test adp.data["echo_intensity"][2, 2, :] == [0x36, 0x30, 0x33, 0x2f]
@test adp.data["percent_good"][1, 1, :] == [0x64, 0x64, 0x64, 0x64]
@test adp.data["percent_good"][1, 2, :] == [0x64, 0x64, 0x64, 0x64]
@test adp.data["percent_good"][2, 1, :] == [0x64, 0x64, 0x64, 0x64]
