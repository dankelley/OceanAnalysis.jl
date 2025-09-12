# Time: 4s with 1 file, 7s with 975 files -- approximately 300 files per second

# NOTES (all files are in /users/kelley/argo):
# D6902967_133.nc -- no LONGITUDE
# BR6902958_xxx.nc -- no PSAL
using OceanAnalysis, Glob
dir = "/Users/kelley/data/argo"
files = glob("*.nc", dir)
#files = [files[100]] # to test a single random file

debug = 0
bad = 0
for (i, file) in enumerate(files)
    short = replace(file, r".*/" => "")
    try
        d = read_argo(file, debug=debug)
        println(i, ". ", short, " [mode:", d.metadata["data_mode"], ", time:",
            d.metadata["time"], ", latitude:",
            round(d.metadata["latitude"], digits=3), ", longitude:",
            round(d.metadata["longitude"], digits=3), ", levels:",
            length(d.data.pressure), "]")
        if length(files) == 1
            tmp = keys(d.metadata)
            println("metadata names: ", sort(collect(tmp)))
            tmp = names(d.data)
            println("data names: ", sort(collect(tmp)))
        end
    catch e
        println(i, ". ", short, " -- ", e)
        global bad = bad + 1
    end
end
println("Read ", length(files), " files, ", bad, " of which are faulty")
