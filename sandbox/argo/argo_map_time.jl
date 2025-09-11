# Map Argo sampling by year
using Dates, CSV, DataFrames, Plots, OceanAnalysis
index_file = get_argo_index("~/data/argo/ss")
df = read_argo_index(index_file)
coastline_file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "coastline.csv.gz");
coastline = CSV.read(coastline_file, DataFrame, header=1)
for year in 1990:2025
    tstart = DateTime("$(year)-01-01")
    tend = tstart + Dates.Year(1)
    look = tstart .<= df.time .< tend
    if sum(look) > 0
        df2 = df[look, :]
        scatter(df2.longitude, df2.latitude,
            markersize=1.0, color=:blue2, markerstrokecolor=:blue2,
            xlimits=(-180, 180), ylimits=(-90, 90), aspect_ratio=:equal,
            framestyle=:box, dpi=500, legend=false,
            title="Year $year: $(nrow(df2)) profiles", titlefontsize=10)
        plot!(coastline.longitude, coastline.latitude, color=:sienna4)
        savefig("argo_map_time_$(year).png")
    end
end
