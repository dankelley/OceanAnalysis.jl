function running(x::Vector{Float64}, k::Int64=3, f::Function=mean)
    if k < 1
        error("k (=$k) is not a positive integer")
    end
    if k == 1
        return (x)
    end
    if 1 != k % 2
        @warn "k increased from $k to $(k+1) to get centred results"
        k = k + 1
    end
    k2 = Int(floor(k / 2))
    n = length(x)
    y = copy(x) # could also start with undef and just do the ends
    window = 1:k
    #println(window)
    for i in (k2+1):(n-k2)
        y[i] = f(skipmissing(x[window]))
        window = window .+ 1
    end
    #println(window)
    #println("n=$n")
    #println("start $(k2+1), end $(n-k2-1)")
    y
end

"""
    running_mean(x::vector{float64}, k::int64=3)

Compute running mean of a vector `x`, over a window of width `k`.

# Examples

```julia
i = 1:100
x = sin.(2 * pi * i / 50)
ymean = running_mean(x, 3)
scatter(x, label="data", ms=2)
plot!(ymean, label="mean")
```
"""
function running_mean(x::Vector{Float64}, k::Int64=3)
    running(x, k, mean)
end
export running_mean


"""
    running_median(x::vector{float64}, k::int64=3)

Compute running median of a vector `x`, over a window of width `k`.

# Examples

```julia
i = 1:100
x = sin.(2 * pi * i / 50)
ymedian = running_median(x, 3)
scatter(x, label="data", ms=2)
plot!(ymedian, label="median")
```
"""
function running_median(x::Vector{Float64}, k::Int64=3)
    running(x, k, median)
end
export running_median

