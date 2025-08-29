# Some 'BR' floats that lack PSAL (detected by OceanAnalysis julia code)
# The first file used here is the one I found, randomly.  The other is
# another file starting with BR (not same float ID) that also lacks
# salinity.
using OceanAnalysis
using NCDatasets
#files = ("BR4902576_017.nc", "BR4902577_016.nc")
file = "BR4902576_017.nc"
if isfile(file)
    println("File: ", file, "\n")
    try
        d = read_argo(file, debug=1)
    catch e
        println("problem with file ($e)")
    end
    println("data starts: $(first(d.data, 3))")
    # data = NCDataset(file, "r") do ds
    #     if haskey(ds, "PSAL")
    #         println(" -- have salinity")
    #     end
    #     if haskey(ds, "TEMP")
    #         println(" -- have temperature")
    #     end
    # end
end
