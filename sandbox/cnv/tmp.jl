using OceanAnalysis, Dates, Plots
#file = "/Users/kelley/git/OceanAnalysis.jl/data/ctd.cnv"
#file = "/Users/kelley/data/arctic/beaufort/2012/d201211_0056.cnv"
#file = "/Users/kelley/data/arctic/beaufort/2004/d200416_049.cnv"

#/Users/kelley/data/arctic/beaufort/2005/d200504_004.cnv:** Latitude: 68 42.0 N
#/Users/kelley/data/arctic/beaufort/2005/d200504_005.cnv:* NMEA Latitude = 70 33.09 N
files = ["/Users/kelley/data/arctic/beaufort/2005/d200504_001.cnv";
    "/Users/kelley/data/arctic/beaufort/2005/d200504_005.cnv"]
files = ["/Users/kelley/Dropbox/oce-working-notes/cnv/ctd.cnv"]
for file in files
    d = read_ctd_cnv(file, debug=0)
    println(d.metadata["filename"], " @ ", d.metadata["latitude"], "N and ", d.metadata["longitude"], "E")
    #print(keys(d.metadata))
    #println(names(d.data))
    #print(first(d.data, 3))
    #plot_TS(d)
end
