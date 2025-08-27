using OceanAnalysis, Glob
files = glob("*.cnv", "/Users/kelley/Dropbox/oce-working-notes/cnv")
files = sort(files)
bad = 0
for file in files
    #println("$file")
    try
        d = read_ctd_cnv(file)
    catch e
        global bad = bad + 1
        println("    $e")
    end
end
println("Got errors in $bad of the $(length(files)) files")
