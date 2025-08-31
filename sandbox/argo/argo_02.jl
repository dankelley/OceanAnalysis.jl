# %%
using OceanAnalysis, Glob

dir = "/Users/kelley/data/argo"
files = glob("*.nc", dir)
nfiles = length(files)
println("There are $nfiles netcdf files in $dir")

m = 10
look = rand(1:nfiles, m)
for i in look
    file = files[i]
    try
        local d = read_argo(file)#, debug=1)
        println("$file: $(length(d.data.pressure)) levels on $(d.metadata["time"]) at $(round(d.metadata["latitude"], digits=4))N, $(round(d.metadata["longitude"], digits=4))E")
    catch
        println("$e")
    end
end
