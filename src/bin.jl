"""
    bin_mean(x, y, bins, debug::Integer=0)

Categorize `x` values into bins with boundaries given by `bins`. Within each
bin, compute the mean `x`, the mean `y` and the number of points in that bin.

# Return value

`bin_mean` returns a DataFrame with columns named `bin_center`, `bin_mean_x`,
`bin_mean_y` and `bin_count`. Any bin with no data gets the corresponding
`bin_mean_x` and `bin_mean_y` set to NaN.

# Examples
```julia
using OceanAnalysis, Plots
x = 0.0:1.0:180.0
y = sin.(x * pi / 180);
a = bin_mean(x, y, x[1]-5:10.0:x[end]+5);
scatter(x, y, ms=1, label="Data", xlab="x", ylab="y",
    legend=:bottom, framestyle=:box, tickdirection=:out,
    title="Binning test")
scatter!(a.bin_center, a.bin_y_mean, ms=4,
    xlim=xlims(), ylim=ylims(), label="binned y vs bin")
scatter!(a.bin_x_mean, a.bin_y_mean, ms=2,
    xlim=xlims(), ylim=ylims(), label="binned y vs binned x")
```
"""
function bin_mean(x, y, bins)
    length(x) == length(y) || throw(Argumenterror("lengths of x ($(length(x))) and y ($(length(y))) do not match"))
    bin_step = step(bins)
    bin_bdy = first(bins) - bin_step / 2
    n = length(bins)
    bin_x_sum = zeros(Float64, n)
    bin_y_sum = zeros(Float64, n)
    bin_count = zeros(Int64, n)
    for i in eachindex(x)
        j = Integer(round((x[i] - bin_bdy) / bin_step))
        if 1 <= j & j <= n
            bin_y_sum[j] = bin_y_sum[j] + y[i]
            bin_x_sum[j] = bin_x_sum[j] + x[i]
            bin_count[j] = bin_count[j] + 1
        end
    end
    DataFrame(bin_center=bins .+ bin_step / 2,
        bin_x_mean=bin_x_sum ./ bin_count,
        bin_y_mean=bin_y_sum ./ bin_count,
        bin_count=bin_count)
end
export bin_mean

