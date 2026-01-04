using Dates, Plots, OceanAnalysis, Test

#file = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
adp = read_adp_rdi(file); # 0.6s for 9-profile case

tm_expected = [1.4619022 -1.4619022 0.0000000 0.0000000;
    0.0000000 0.0000000 -1.4619022 1.4619022;
    0.2660444 0.2660444 0.2660444 0.2660444;
    1.0337210 1.0337210 -1.0337210 -1.0337210]
@test adp["transformation_matrix"] ≈ tm_expected atol = 1e-5
@test adp["beam_configuration"] == :four_beam_janus
@test adp["convex"] == true


# R tm.c <- if (res@metadata$beamPattern == "convex") 1 else -1 # control sign of first 2 rows of transformationMatrix
# R tm.a <- 1 / (2 * sin(res@metadata$beamAngle * pi / 180))
# R tm.b <- 1 / (4 * cos(res@metadata$beamAngle * pi / 180))
# R tm.d <- tm.a / sqrt(2)
# R res@metadata$transformationMatrix <- matrix(
# R     c(
# R         tm.c * tm.a, -tm.c * tm.a, 0, 0,
# R         0, 0, -tm.c * tm.a, tm.c * tm.a,
# R         tm.b, tm.b, tm.b, tm.b,
# R         tm.d, tm.d, -tm.d, -tm.d
# R     ),
# R     nrow = 4, byrow = TRUE
# R )
#           [,1]       [,2]       [,3]       [,4]
# [1,] 1.4619022 -1.4619022  0.0000000  0.0000000
# [2,] 0.0000000  0.0000000 -1.4619022  1.4619022
# [3,] 0.2660444  0.2660444  0.2660444  0.2660444
# [4,] 1.0337210  1.0337210 -1.0337210 -1.0337210
#
# more oce::read.adp
# $ orientation                  : chr [1:9] "upward" "upward" "upward" "upward" ...
# $ instrumentType               : chr "adcp"
# $ instrumentSubtype            : chr "workhorse"
# $ firmwareVersionMajor         : int 16
# $ firmwareVersionMinor         : int 28
# $ firmwareVersion              : chr "16.28"
# $ bytesPerEnsemble             : int 1832
# $ systemConfiguration          : chr "11001011-01000001"
# $ frequency                    : num 600
# $ beamAngle                    : num 20
# $ beamPattern                  : chr "convex"
# $ beamConfig                   : chr "janus"

println("+ add 'orientation'           DONE")
println("+ add 'transformation_matrix' DONE")
println("+ add 'convex'                DONE")
println("+ add 'beam_configuration'    DONE")
#println("- add 'type'               -- workhorse")

