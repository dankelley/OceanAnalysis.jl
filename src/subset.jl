using OceanAnalysis
function subset_data(x::OA, rows=missing, debug::Int64=0)
    println("in subset_data")
    !ismissing(rows) || error("must give rows")
    println("% rows: ", 100 * sum(rows) / length(rows))
    metadata
end

c = coastline();

cs = subset_data(c, c.data.latitude .>= 0.0)
#cs = subset_data(c, 1, 1, debug=1)


