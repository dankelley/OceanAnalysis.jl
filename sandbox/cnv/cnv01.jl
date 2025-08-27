using OceanAnalysis, Glob, Plots
files = glob("*.cnv", "/Users/kelley/Dropbox/oce-working-notes/cnv")
files = sort(files)
bad = 0
for (i, file) in enumerate(files)
    file = files[i]
    file_short_name = replace.(file, r".*/" => "", ".cnv" => "")
    try
        d = read_ctd_cnv(file)
        plot_TS(d, title=file, titlefont=font(9))
        png = "cnv01_$(file_short_name).png"
        println(png)
        savefig(png)
    catch e
        global bad = bad + 1
        println("$file\n    $e")
    end
end
println("Got errors in $bad of the $(length(files)) files")
