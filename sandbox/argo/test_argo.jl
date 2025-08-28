# %%
using OceanAnalysis, Glob
dir = "/Users/kelley/data/argo"
files = glob("*.nc", dir)
nfiles = length(files)
println("There are $nfiles netcdf files in $dir")

# %%
# bad files, from running next block and taking notes
bad = "/Users/kelley/data/argo/D6902967_095.nc"
d = read_argo(bad, debug=1)
#println("$bad: $(length(d.data.pressure)) levels at $(d.metadata["date"]) $(round(d.metadata["latitude"], digits=3)) N, $(round(d.metadata["longitude"], digits=3)) E")

# %%
if false
    m = 10
    look = rand(1:nfiles, m)
    for i in look
        file = files[i]
        println("$i: $file")
        try
            local d = read_argo(file)#, debug=1)
        catch
            println("$e")
        end
    end
end
