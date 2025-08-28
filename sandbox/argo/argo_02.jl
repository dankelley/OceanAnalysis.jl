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
    println("$i: $file")
    try
        local d = read_argo(file)#, debug=1)
    catch
        println("$e")
    end
end
