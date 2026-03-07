using OceanAnalysis, Plots, Statistics

"""
    despike(x::Vector{Float64}; k::Int64=7, n::Int64=4)

Despike a timeseries.

The procedure starts by computing a running median version (with window length `k`) of the provided time-series. Then the standard deviation of the difference between the two timeseries is computed. Points are considered to be spikes if they have difference exceeding `n` times the overall standard deviation. Any such points are then replaced with the running-median values, and the resultant possibly-altered timeseries is returned. The default values of `k` and `n` may provide a good starting point, but users are advised to explore other values, in the context of the character of data being analyzed.

# Parameters

- `x` a vector of values representing a timeseries.

# Keywords

- `k` width of running-median filter. This is passed to [`running_median`](@ref), which computes the running mean. Since the computation uses centred windows, `k` will be incremented by 1 if it is an even number.
- `n` spike criterion. Increasing `n` will usually decrease the number of points considered spikes, unless they are very anomalous.

# Examples

```julia
using OceanAnalysis, Plots
i = 1:40;
x0 = sin.(2 * pi * i / 40);
x = x0 .+ (rand(length(x0)) .- 0.5) / 10.0
x[10] = x[10] + 1
xd = despike(x)
plot(i, x0, label="base", ms=3)
scatter!(i, x, label="base+noise")
scatter!(i, xd, label="despiked", ms=2)
```
"""
function despike(x; k::Int64=7, n::Int64=4)
    x_smoothed = running_median(x, k)
    distance = abs.(x .- x_smoothed)
    stddev = std(distance)
    bad = distance .> n * stddev
    if sum(bad) > 0
        x = ifelse.(bad, x_smoothed, x)
    end
    x
end
