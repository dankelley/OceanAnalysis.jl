using OceanAnalysis, Plots, Statistics

"""
    despike(x::Vector{Float64}; k::Int64=2, n::Int64=3)

Despike a timeseries.

The procedure starts by computing a running median version of the provided time-series. Then, each point is compared with the sliding-median within a sliding window, with the standard deviation of the departure being computing in each window. If any given point departs from the running median by more than `n` time that local standard deviation, then it is considered an outlier, and it is replaced with the running median. Points near the start and end of `x` are left unaltered, to ensure that the window about any given point is centred.

# Parameters

- `x` a vector of values representing a timeseries.

# Keywords

- `k` width of running-median filter. This is passed to [`running_median`](@ref), which computes the running mean.
- `n` spike criterion.

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
function despike(x; n::Int64=2, k::Int64=3)
    x_smoothed = running_median(x, k)
    distance = abs.(x .- x_smoothed)
    stddev = std(distance)
    bad = distance .> n * stddev
    if sum(bad) > 0
        x = ifelse.(bad, x_smoothed, x)
    end
    x
end
