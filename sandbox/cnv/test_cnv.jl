# %%
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

# Test a bad-location file
# files = ["/Users/kelley/data/arctic/beaufort/2009/d200920_007.cnv"]
# files = ["/Users/kelley/data/arctic/beaufort/2009/d200920_005.cnv"]
# files = ["/Users/kelley/data/arctic/beaufort/2009/d200920_006.cnv"]
# files = ["/Users/kelley/data/arctic/beaufort/2009/d200920_007.cnv"]
# files = ["/Users/kelley/data/arctic/beaufort/2009/d200920_008.cnv"]

files = ["/Users/kelley/Dropbox/oce-working-notes/cnv/vert_01.cnv"]


# %%
debug = 0
bad = 0
for (i, file) in enumerate(files)
    file_short_name = replace.(file, r".*/" => "", ".cnv" => "")
    try
        print(i, ". ", file)
        d = read_ctd_cnv(file, debug=debug)
        print(": ", d.metadata["time"], " @ ", round(d.metadata["latitude"], digits=3), " N, ", round(d.metadata["longitude"], digits=3), " E\n")
    catch e
        global bad = bad + 1
        print(" FAILURE TO READ ", e, "\n")
    end
end
println("Got errors in $bad of the $(length(files)) files")
