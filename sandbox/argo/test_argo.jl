# Time: 4s with 1 file, 6.5s with 975 files -- approximately 500 files per second

# NOTES (all files are in /users/kelley/argo):
# D6902967_133.nc -- no LONGITUDE
# BR6902958_xxx.nc -- no PSAL
using OceanAnalysis, Glob, Random
#Random.seed!(1234)
dir = "/Users/kelley/data/argo"
files = glob("*.nc", dir)
#files = [dir * "/R4902911_202.nc"]

bad = 0
for i = eachindex(files)
    file = files[i]
    short = replace(file, r".*/" => "")
    try
        d = read_argo(file)
        println("$short $(d.metadata["time"]) @ $(round(d.metadata["latitude"], digits=3))N $(round(d.metadata["longitude"], digits=3))E $(length(d.data.pressure)) levels")
    catch e
        println("$short -- $e")
        global bad = bad + 1
    end
end
println("Read ", length(files), ", ", bad, " of which are faulty")
