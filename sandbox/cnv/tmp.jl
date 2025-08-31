using OceanAnalysis
files = ["/Users/kelley/data/arctic/beaufort/2005/d200504_001.cnv";
    "/Users/kelley/data/arctic/beaufort/2005/d200504_005.cnv";
    "/Users/kelley/Dropbox/oce-working-notes/cnv/AS_CTD_20130821_c043.cnv"]
for file in files
    d = read_ctd_cnv(file, debug=0)
    println(d.metadata["filename"], " @ ", d.metadata["latitude"], " N and ", d.metadata["longitude"], " E")
    println("  first(d.data, 2)")
    println(first(d.data, 2))
    print(keys(d.metadata))
    print(first(d.data, 2))
end
