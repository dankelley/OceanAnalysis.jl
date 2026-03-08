using OceanAnalysis, Plots, Statistics

"""
    despike(x; k::Int64=7, n::Int64=4, action::Symbol=:replace)

Despike a timeseries, or reveal spikes.

The procedure starts by computing a running median version (with window length `k`) of the provided time-series. Then the standard deviation of the difference between the two timeseries is computed. Points are considered to be spikes if they have difference exceeding `n` times the overall standard deviation. Any such points are then replaced with the running-median values, and the resultant possibly-altered timeseries is returned. The default values of `k` and `n` may provide a good starting point, but users are advised to explore other values, in the context of the character of data being analyzed.

# Parameters

- `x` a vector of values representing a timeseries.

# Keywords

- `k` width of running-median filter. This is passed to [`running_median`](@ref), which computes the running mean. Since the computation uses centred windows, `k` will be incremented by 1 if it is an even number.
- `n` spike criterion. Increasing `n` will usually decrease the number of points considered spikes, unless they are very anomalous.
- `action` a Symbol indicating what to do with spikes. If this is `:replace` (which is the default) then spikes are replaced with the corresponding running-median values. If it is `:NaN` then they are replaced with NaN values. And, if it is `:reveal` then a BitVector is returned, with 0 at the indices of non-spike values and 1 at the indices of spike values.

# Return value

Either a Float64 vector (if `action` is `:replace` or `:NaN`) or a logical BitVector (if `action` is `:reveal`).

# Examples

```julia
using OceanAnalysis, Plots
i = 1:40;
x0 = sin.(2 * pi * i / 40);
x = x0 .+ (rand(length(x0)) .- 0.5) / 10.0;
x[10] = x[10] + 1;
xd = despike(x);
# Plot 'base' (before noise), 'signal' (base + noise) and 'despiked'
plot(i, x0, label="base", ms=3)
scatter!(i, x, label="signal")
scatter!(i, xd, label="despiked", ms=2)
# Print overview of spikes (show it and nearest neighbours)
spike_indices = findall(despike(x, action=:flag));
for index in spike_indices
    println(x[index.+range(-1, 1)])
end
```
"""
function despike(x; k::Int64=7, n::Int64=4, action::Symbol=:replace)
    x_smoothed = running_median(x, k)
    distance = abs.(x .- x_smoothed)
    stddev = std(distance)
    bad = distance .> n * stddev
    if action == :NaN
        return (ifelse.(bad, NaN, x))
    elseif action == :replace
        return (ifelse.(bad, x_smoothed, x))
    elseif action == :flag
        return (bad)
    else
        error("'action' must be :replace, :NaN or :flag")
    end
end
