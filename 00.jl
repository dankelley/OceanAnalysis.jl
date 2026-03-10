using OceanAnalysis, Printf, Statistics, DataFrames
ctd = read_ctd_cnv("data/ctd.cnv");
argo = read_argo("data/D4902911_095.nc");

function four_num(x, name)
    skip_missing = ismissing.(x)
    skip_nan = isnan.(x)
    X = filter(!isnan, x)
    X = skipmissing(X)
    Min, Max = extrema(X)
    Mean = mean(X)
    number_missing = sum(skip_missing)
    number_nan = sum(skip_nan)
    (name, Min, Mean, Max, number_missing, number_nan)
end

function summary(x::OA)
    println("OA Summary\n----------\n")
    println("Metadata: a Dict() with ", length(x.metadata), " entries")
    # FIXME: what if data is a matrix, or a Dict ...?
    if x.data isa DataFrame
        println("\nData: a DataFrame with summary contents as follows")
        df = DataFrame(name=String[], Min=Float64[], Max=Float64[], Mean=Float64[],
            num_missing=Int64[], num_nan=Int64[])
        for name in names(ctd.data)
            push!(df, four_num(ctd[name], name))
        end
        indent = "  "
        println(indent, replace(string(df), "\n" => "\n" * indent))
    end
end

function summary(x::Ctd)
    println("CTD Summary\n-----------\n")
    println("Metadata: a Dict with ", length(x.metadata), " keys, including the following")
    println("  filename:  ", x.metadata["filename"])
    println("  latitude:  ", @sprintf "%.3fN" x.metadata["latitude"])
    println("  longitude: ", @sprintf "%.3fE" x.metadata["longitude"])
    println("  header:    String vector with ", length(x.metadata["header"]), " entries")
    println("\nData: a DataFrame with summary contents as follows")
    df = DataFrame(name=String[], Min=Float64[], Max=Float64[], Mean=Float64[],
        num_missing=Int64[], num_nan=Int64[])
    for name in names(ctd.data)
        push!(df, four_num(ctd[name], name))
    end
    indent = "  "
    println(indent, replace(string(df), "\n" => "\n" * indent))
end

summary(argo)

summary(ctd)

