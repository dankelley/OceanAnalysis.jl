import StatsBase

function six_num(x, name)::NamedTuple{(:name, :min, :mean, :max, :number, :number_missing, :number_nan)}
    if !(x[1] isa Char)
        number = length(x)
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
        (name=name, min=Min, mean=Mean, max=Max, number=number, number_missing=number_missing, number_nan=number_nan)
    else
        (name=name, min=NaN, mean=NaN, max=NaN, number=number, number_missing=0, number_nan=0)
    end
end

function summarize_data(x)
    if x.data isa DataFrame
        data_names = names(x.data)
        println("\nData: a DataFrame, summarized as follows")
        df = DataFrame("name" => String[],
            "min" => Float64[], "mean" => Float64[], "max" => Float64[],
            "#total" => Int64[], "#missing" => Int64[], "#NaN" => Int64[])
        for name in data_names[.!occursin.(r"_qc$", data_names)]
            push!(df, six_num(x[name], name))
        end
        indent = "  "
        println(indent, replace(string(df), "\n" => "\n" * indent))
        # Summarize QC flags (if they exist)
        QC_names = data_names[occursin.("_qc", data_names)]
        if length(QC_names) > 0
            println("\nData-Processing Flags:")
            for name in QC_names
                local tmp = StatsBase.countmap(x[name])
                print(@sprintf "  %-25s " name * ":")
                local i = length(keys(tmp))
                for key in keys(tmp)
                    print("\"$key\" $(tmp[key])")
                    i = i - 1
                    if i >= 1
                        print(", ")
                    end
                end
                print("\n")
            end
        end
    elseif x.data isa Matrix
        sn = six_num(x.data, "")
        nrow, ncol = size(x.data)
        println("\nData: a $(nrow)×$(ncol) Matrix, summarized as follows")
        println("  minimum: ", sn.min)
        println("  mean: ", sn.mean)
        println("  maximum: ", sn.max)
        println("  number of values: ", sn.number)
        println("  number of missing values: ", sn.number_missing)
        println("  number of NaN values: ", sn.number_nan)
    else
        println("\nData: a $(typeof(x.data)) object")
    end
end

"""
    summarize(x::OA)

Print a summary of some of the contents of an OA object.
"""
function summarize(x::OA)
    println("OA Summary\n----------\n")
    println("Metadata: a Dict() with ", length(x.metadata), " entries")
    summarize_data(x)
end

"""
    summarize(x::Argo)

Print a summary of some of the contents of an Argo object. This includes some
entries in both `x.metadata` and `x.data`. Additionally,
[`summarize_argo_data_tests`](@ref) is called, to show the list of tests that
have been performed on the dataset before inclusion in the archive.

# Examples

```juliadoc
using OceanAnalysis
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "D4902911_095.nc");
a = read_argo(f);
summarize(a)
```
"""
function summarize(x::Argo)
    println("Argo Summary\n------------\n")
    println("Metadata: a Dict with ", length(x.metadata), " keys, including the following")
    filename = x.metadata["filename"]
    println("  filename:  \"", filename, "\"")
    println("  time:      ", x.metadata["time"])
    println("  latitude:  ", @sprintf "%.3fN" x.metadata["latitude"])
    println("  longitude: ", @sprintf "%.3fE" x.metadata["longitude"])
    println("  data_mode: ", x.metadata["data_mode"])
    summarize_data(x)
    println("Tests applied to the dataset")
    summarize_argo_data_tests(filename)
end


"""
    summarize(x::Ctd)

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
    k = keys(x.metadata)
    if length(k) == 0
        println("Metadata: an empty Dict")
    else
        println("Metadata: a Dict with ", length(x.metadata), " keys, including the following")
        if "filename" in k && !isnothing(x.metadata["filename"])
            println("  filename:  \"", x.metadata["filename"], "\"")
        end
        if "latitude" in k
            println("  latitude:  ", @sprintf "%8.3f N" x.metadata["latitude"])
        end
        if "longitude" in k
            println("  longitude: ", @sprintf "%8.3f E" x.metadata["longitude"])
        end
        if "time" in k && !isnothing(x.metadata["time"])
            println("  time:      ", x.metadata["time"])
        end
        if "header" in keys(x.metadata)
            println("  header:    String vector with ", length(x.metadata["header"]), " entries")
        end
    end
    nr = nrow(x.data)
    if nr == 0
        println("Data: an empty data frame")
    else
        summarize_data(x)
    end
end

"""
    summarize(x::Topo)

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


