# Argo maps by time for class
using Dates, CSV, DataFrames, Plots, OceanAnalysis
@time download_argo_index("~/data/argo/ss")
@time df = read_argo_index("~/data/argo/ss/ar_index_global_prof.txt.gz")
coastline_file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "coastline.csv.gz");
coastline = CSV.read(coastline_file, DataFrame, header=1)
for year in 1990:2025
    tstart = DateTime("$(year)-01-01")
    tend = tstart + Dates.Year(1)
    look = (tstart .<= df.time) .* (df.time .< tend) # FIXME: why can't we use .& here?
    if sum(look) > 0
        println(sum(look))
        df2 = df[look, :]
        title = "Year $year: $(nrow(df2)) profiles"
        @time scatter(df2.longitude, df2.latitude,
            markersize=1.0, color=:blue2, markerstrokecolor=:blue2,
            xlimits=(-180, 180), ylimits=(-90, 90), aspect_ratio=:equal,
            framestyle=:box, dpi=500, legend=false,
            title=title, titlefontsize=10)
        plot!(coastline.longitude, coastline.latitude, color=:sienna4)
        savefig("argo_map_time_$(year).png")
        println(title)
    end
end
