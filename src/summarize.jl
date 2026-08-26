import StatsBase, Dates

"""
    six_num(x, name)

Compute six numbers for a vector or matrix `x`, identified by the String `name`. This is
used by `summarize`.

# Return value

This returns a NamedTuple with entries `name` (a copy of `name`), `min` (the
minimum value in `x`), `mean` (the mean value in `x`), `max` (the maximum value
in `x`), `number` (the number of values in `x`), `number_missing` (the number
of missing values in `x`), and `number_NaN` (the number of NaN values in `x`).
"""
function six_num(x, name::String)::NamedTuple{(:name, :min, :mean, :max, :number, :number_missing, :number_NaN)}
    xx = vec(copy(x))
    number = length(xx)
    if isa(xx[1], Char)
        return (name=name, min=NaN, mean=NaN, max=NaN, number=length(x), number_missing=0, number_NaN=0)
    end
    number_missing = count(ismissing, xx)
    if number_missing == number
        return (name=name, min=NaN, mean=NaN, max=NaN, number=number, number_missing=number, number_NaN=0)
    end
    # remove missing values (already counted)
    filter!(!ismissing, xx)
    # Similarly, count and then remove NaN values
    number_NaN = count(isnan, xx)
    if number_NaN > 0
        filter!(!isnan, xx)
    end
    if length(xx) > 0
        Min, Max = extrema(xx)
        Mean = mean(xx)
    else
        Min, Max, Mean = NaN, NaN, NaN
    end
    return (name=name, min=Min, mean=Mean, max=Max, number=number, number_missing=number_missing, number_NaN=number_NaN)
end
export six_num



function summarize_data(x)
    if x.data isa DataFrame
        data_names = names(x.data)
        # Handle time (if it is a DateTime) separately, because cannot do mean(DateTime)
        if "time" in data_names
            val = x.data.time
            if eltype(val) <: Union{Missing,DateTime} || eltype(val) <: DateTime
                println(@sprintf "\nTime ranges from %s to %s with mean step %.1f s and median step %.1f s" minimum(val) maximum(val) mean(diff(datetime2unix.(val))) median(diff(datetime2unix.(val))))
                println("\nData summary (skipping the time data):")
            end
        else
            println("\nData summary:")
        end
        df = DataFrame("name" => String[],
            "min" => Float64[], "mean" => Float64[], "max" => Float64[],
            "number" => Int64[], "number_missing" => Int64[], "number_NaN" => Int64[])
        for name in data_names[.!occursin.(r"_qc$", data_names)]
            val = x[name]
            # Skip DateTime columns (need Union because there are often some missing values)
            if !(eltype(val) <: Union{Missing,DateTime}) && !(eltype(val) <: DateTime)
                push!(df, six_num(val, name))
            end
        end
        indent = "  "
        println(indent, replace(string(df), "\n" => "\n" * indent))
        # Summarize QC flags (if they exist)
        QC_names = data_names[occursin.("_qc", data_names)]
        if length(QC_names) > 0
            println("\nQuality-Control Flags:")
            for name in QC_names
                # Insist that *_qc items have Integer or Char values, because
                # I encountered a glider file (sbloom2003) that had
                # depth_qc==depth and similar errors for longitude_qc
                # and latitude_qc, spewing 6M lines of output here.
                val = x[name]
                et = eltype(val)
                print(@sprintf "  %-25s " name * ":")
                if et <: Union{Missing,Integer} || et <: Integer || et <: Union{Missing,Char} || et <: Char
                    local tmp = StatsBase.countmap(val)
                    local i = length(keys(tmp))
                    for key in keys(tmp)
                        print("\"$key\" $(tmp[key])")
                        i = i - 1
                        if i >= 1
                            print(", ")
                        end
                    end
                    print("\n")
                else
                    print("misconfigured (values neither Integer nor Char)\n")
                end
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
        println("  number of NaN values: ", sn.number_NaN)
    else
        println("\nData: a $(typeof(x.data)) object")
    end
end

"""
    summarize(x::OA)

Print a summary of some of the contents of an OA object.
"""
function summarize(x::OA)
    t = typeof(x)
    println("$t Summary")
    println(repeat("-", length(repr(t))) * "--------\n")
    println("Metadata: a Dict() with entries: ", sort(collect(keys(x.metadata))))
    summarize_data(x)
end
export summarize



"""
    summarize(x::Argo)

Print a summary of some of the contents of an Argo object. This includes some
entries in both `x.metadata` and `x.data`. Additionally,
[`summarize_argo_data_tests`](@ref) is called, to show the list of tests that
have been performed on the dataset before inclusion in the archive.

# Examples

```julia
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
    println(@sprintf("  filename:      \"%s\"", filename))
    println(@sprintf("  time:          %s", x.metadata["time"]))
    println(@sprintf("  latitude:      %.3fN", x.metadata["latitude"]))
    println(@sprintf("  longitude:     %.3fE", x.metadata["longitude"]))
    println(@sprintf("  data_mode:     %s", x.metadata["data_mode"]))
    println(@sprintf("  data_centre:   %s", x.metadata["data_centre"]))
    println(@sprintf("  profiler_type: %s", x.metadata["profiler_type"]))
    summarize_data(x)
    println("Tests applied to the dataset")
    summarize_argo_data_tests(filename)
end


"""
    summarize(x::Ctd)

Print a summary of some of the contents of a Ctd object.

# Examples

```julia
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
            println(@sprintf("  latitude:  %8.3f N", x.metadata["latitude"]))
        end
        if "longitude" in k
            println(@sprintf("  longitude: %8.3f E", x.metadata["longitude"]))
        end
        if "time" in k && !isnothing(x.metadata["time"])
            println("  time:      ", x.metadata["time"])
        end
        if "header" in keys(x.metadata)
            if isa(x.metadata["header"], Vector)
                println("  header:    String vector with ", length(x.metadata["header"]), " entries")
            else
                println("  header:    String with ", length(x.metadata["header"]), " characters")
            end
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


