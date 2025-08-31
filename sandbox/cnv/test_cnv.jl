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

# %%
bad = 0
for (i, file) in enumerate(files)
    print(file)
    file = files[i]
    file_short_name = replace.(file, r".*/" => "", ".cnv" => "")
    try
        d = read_ctd_cnv(file)
        println(d.metadata)
        stop("DAN")
        print(" OK\n")
        #plot_TS(d, title=file, titlefont=font(9))
        #png = "cnv01_$(file_short_name).png"
        #println(png)
        #savefig(png)
    catch e
        global bad = bad + 1
        print(" FAILURE TO READ ", e, "\n")
    end
end
println("Got errors in $bad of the $(length(files)) files")
