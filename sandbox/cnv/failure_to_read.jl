using OceanAnalysis
files = ["/Users/kelley/Dropbox/oce-working-notes/cnv/JR302_001_align_ctm.cnv";
    "/Users/kelley/Dropbox/oce-working-notes/cnv/first_CTD_cast.cnv"]
d = read_ctd_cnv(files[2], debug=0)
println(d.metadata["filename"], " @ ", d.metadata["latitude"], " N and ", d.metadata["longitude"], " E")
println("  first(d.data, 2)")
println(first(d.data, 2))

