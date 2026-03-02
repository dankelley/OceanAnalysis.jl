function four_num(x, name)
    if !(x[1] isa Char)
        skip_missing = ismissing.(x)
        skip_nan = isnan.(x)
        X = filter(!isnan, x)
        if count(!ismissing, X) > 0
            X = skipmissing(X)
            Min, Max = extrema(X)
            Mean = mean(X)
        else
            Min, Max, Mean = NaN, NaN, NaN
        end
        number_missing = sum(skip_missing)
        number_nan = sum(skip_nan)
        (name, Min, Mean, Max, number_missing, number_nan)
    else
        (name, NaN, NaN, NaN, 0, 0)
    end
end

function summarize_data(x)
    if x.data isa DataFrame
        println("\nData: a DataFrame with contents as follows")
        df = DataFrame(name=String[], Min=Float64[], Max=Float64[], Mean=Float64[],
            num_missing=Int64[], num_nan=Int64[])
        for name in names(x.data)
            push!(df, four_num(x[name], name))
        end
        indent = "  "
        println(indent, replace(string(df), "\n" => "\n" * indent))
    elseif x.data isa Matrix
        fn = four_num(x.data, "")
        nrow, ncol = size(x.data)
        println("\nData: a $(nrow)×$(ncol) Matrix with contents as follows")
        println("  minimum: ", fn[2])
        println("  maximum: ", fn[4])
        println("  number of missing values: ", fn[5])
        println("  number of NaN values: ", fn[6])
    else
        println("\nData: a $(typeof(x.data)) object")
    end
end

"""
    summary(x::OA)

Print a summary of some of the contents of an OA object.
"""
function summarize(x::OA)
    println("OA Summary\n----------\n")
    println("Metadata: a Dict() with ", length(x.metadata), " entries")
    summarize_data(x)
end

"""
    summary(x::Ctd)

Print a summary of some of the contents of a Ctd object.

# Examples

```juliadoc
using OceanAnalysis
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
d = read_ctd_cnv(f, add_teos=false);
summarize(d)
```
"""
function summarize(x::Ctd)
    println("CTD Summary\n-----------\n")
    println("Metadata: a Dict with ", length(x.metadata), " keys, including the following")
    println("  filename:  \"", x.metadata["filename"], "\"")
    println("  latitude:  ", @sprintf "%.3fN" x.metadata["latitude"])
    println("  longitude: ", @sprintf "%.3fE" x.metadata["longitude"])
    println("  header:    String vector with ", length(x.metadata["header"]), " entries")
    summarize_data(x)
end

"""
    summary(x::Topo)

Print a summary of some of the contents of a Topography object.
"""
function summarize(x::Topography)
    println("Topography Summary\n------------------\n")
    println("Metadata: a Dict with ", length(x.metadata), " keys, including the following")
    println("  filename: \"", x.metadata["filename"], "\"")
    println("  latitude:  a vector of length ", length(x.metadata["latitude"]))
    println("  longitude: a vector of length ", length(x.metadata["longitude"]))
    summarize_data(x)
end


