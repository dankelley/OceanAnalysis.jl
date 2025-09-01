# NOTES (all files are in /users/kelley/argo):
# D6902967_133.nc -- no LONGITUDE
# BR6902958_161.nc -- no PSAL
# BR4902576_017.nc -- no PSAL
# BR4902578_012.nc -- no PSAL
# BR4902576_016.nc -- no PSAL
# BR4903273_048.nc -- no PSAL
using OceanAnalysis, Glob, Random
#Random.seed!(1234)
dir = "/Users/kelley/data/argo"
files = glob("*.nc", dir)
files = [dir * "/R4902911_202.nc"]

for i = eachindex(files)
    file = files[i]
    short = replace(file, r".*/" => "")
    d = read_argo(file, debug=1)
    #DAN try
    #DAN     local d = read_argo(file, debug=1)
    #DAN     println("$short $(d.metadata["time"]) @ $(round(d.metadata["latitude"], digits=3))N $(round(d.metadata["longitude"], digits=3))E $(length(d.data.pressure)) levels")
    #DAN catch e
    #DAN     println("$short -- errors (FIXME DAN)")
    #DAN     #println("$short -- $e")
    #DAN end
end
