using OceanAnalysis, Glob
files = glob("*.cnv", "/Users/kelley/Dropbox/oce-working-notes/cnv")
files = sort(files)
for file in files
    println("\n$file")
    try
        d = read_ctd_cnv(file)
    catch e
        println("    $e")
    end
end
