using OceanAnalysis, Glob, Dates
files = []
files = [files; glob("*.cnv", "/Users/kelley/Dropbox/oce-working-notes/cnv")]
files = [files; glob("*.cnv", "/Users/kelley/data/archive/sleiwex/2008/ships/coriolisii/ctd/01-cnv")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2004/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2005/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2006/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2007/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2008/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2009/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2010/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2011/")]
files = [files; glob("*.cnv", "/Users/kelley/data/arctic/beaufort/2012/")]
files = sort(files)

# Override the above by uncommenting the next line, to test on a particular file.
# files = ["/Users/kelley/Dropbox/oce-working-notes/cnv/vert_01.cnv"]

bad = 0
for (i, file) in enumerate(files)
    file_short_name = replace.(file, r".*/" => "", ".cnv" => "")
    try
        d = read_ctd_cnv(file)
        print(i, ". ", d.metadata["filename"], ": ",
            Dates.format(d.metadata["time"], "yyyy-mm-dd HH:MM"), ", ",
            trunc(d.metadata["latitude"], digits=2), " N, ",
            trunc(d.metadata["longitude"], digits=2), " E\n")
        if 1 == length(files)
            println("metadata:")
            println(d.metadata)
            println("data:")
            println(first(d.data, 6))
        end
    catch e
        global bad = bad + 1
        print(" ERROR ", e, "\n")
    end
end
println("Got errors in $bad of the $(length(files)) files")
