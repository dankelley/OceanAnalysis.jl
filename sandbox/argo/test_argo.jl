# Time: 4s with 1 file, 6.5s with 975 files -- approximately 500 files per second

# NOTES (all files are in /users/kelley/argo):
# D6902967_133.nc -- no LONGITUDE
# BR6902958_xxx.nc -- no PSAL
using OceanAnalysis, Glob, Random
#Random.seed!(1234)
dir = "/Users/kelley/data/argo"
files = glob("*.nc", dir)
#files = [dir * "/D6902967_127.nc"]
debug = 0
bad = 0
files = [files[100]]
for (i, file) in enumerate(files)
    short = replace(file, r".*/" => "")
    try
        d = read_argo(file, debug=debug)
        println(i, ". ", short, " mode ", d.metadata["data_mode"], " -- ",
            d.metadata["time"], " [",
            round(d.metadata["latitude"], digits=3), " N ",
            round(d.metadata["longitude"], digits=3), " E]; ",
            length(d.data.pressure), " levels")
    catch e
        println(i, ". ", short, " -- ", e)
        global bad = bad + 1
    end
end
println("Read ", length(files), " files, ", bad, " of which are faulty")
