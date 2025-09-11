using OceanAnalysis
file = "/Users/kelley/data/argo/R4902911_202.nc"
isfile(file)
try
    d = read_argo(file)
    println(file, " is okay (but it has no salinity!)")
catch e
    println(e)
end

