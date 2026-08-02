using DataFrames, CSV, Test, Plots, Statistics

# Interpolate z(x,y) to get zz at location (xx,yy). This works by a
# weighted-exponential-mean method. When used to predict at a grid point, set
# skip=0. When used to predictio at a data point, set skip to the index of the
# point in question. The efolding scale in the exponential is set by 'xr' and
# 'yr'. Note that the quantity being interpolated is z-z_last.
function interpolate_barnes_point(xx, yy, zz, skip, x, y, z, w, z_last, xr, yr)
    sum_w = 0.0
    sum = 0.0
    for k in eachindex(x)
        if k != skip
            dx = (xx - x[k]) / xr
            dy = (yy - y[k]) / yr
            weight = w[k] * exp(-(dx^2 + dy^2))
            sum_w += weight
            sum += weight * (z[k] - z_last[k])
        end
    end
    # Return NaN if there are no points in the sum.  (I am not
    # sure this will happen, in real applications.)
    (sum_w > 0.0) ? (zz + sum / sum_w) : NaN
end
export interpolate_barnes


# Compute a Barnes weight for a prediction of zz at a location
# (xx, yy), given a field z defined at locations (x,y). The
# efolding scale for the influence function is determined by
# dividing the distance components (dx,dy) by xr and yr.
#
# This function is used at the very end of interpolate_barnes().
function weight_barnes(xx, yy, skip, x, y, w, xr, yr)
    sum_w = 0.0
    for k in eachindex(x)
        if k != skip
            dx = (xx - x[k]) / xr
            dy = (yy - y[k]) / yr
            sum_w += w[k] * exp(-(dx^2 + dy^2))
        end
    end
    (sum_w > 0.0) ? sum_w : NaN
end

"""
    interpolate_barnes(x, y, z, w=nothing, xg=nothing, yg=nothing;
        xr=nothing, yr=nothing, gamma=0.5, iterations=2, debug=0)

Interpolate a two-dimensional field to a grid, using the Barnes method as
described by Barnes (1994a, 1994b, 1994c). The methodology follows
that of the `interp_barnes` function in the R `oce` package.


# Arguments

- `x` Vector of values for the x coordinate of data points.
- `y` Vector of values for the z coordinate of data points.
- `z` Vector of values for the z values at the (x,y) data points.
- `w` Vector of values for the weights for the data points. If not provided, this defaults to a vector of unit values.

# Keywords

- `xg` Float64 vector giving grid coordinates in the x direction. If not
  provided, this is computed with `pretty(x,50)`.

- `yg` As `xg` but for the `y` direction.

- `xr` Influence scale in the x direction. If not provided,
  this defaults to the range of `x` values, divided by the square root of the
  number of distinct `x` values.

- `yr` As `xr` but for the `y` direction.

- `gamma` scale-reduction parameter (0.5 by default).

- `iterations` number of iterations to perform (2 by default).

- `debug` integer indicating whether to print information during
  processing. The default value of 0 means to work quietly, and any larger
  integer indicates to print some information.

# Value

A Dict with elements named `xg`, `yg` and `zg` that hold the grid coordinates
and values, along with `wg` (the final weights) and `zd` (the values
interpolated at the data coordinates). In addition to these, it has elements
`xr` and `yr` (the initial influence lengths), as well as `gamma` and
`iterations.

# Examples

```julia
using OceanAnalysis, CSV, DataFrames, Statistics, Plots

# 1. Two-dimensional example, using data from references 1,2 and 3.
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "wind.csv")
data = CSV.read(file, DataFrame);
w = repeat([1.0], nrow(data));
xg = range(0.0, 11.0, step=0.2);
yg = range(0.0, 9.0, step=0.2);
res = interpolate_barnes(data.x, data.y, data.z)
scatter(data.x, data.y, framestyle=:box, label=false, ms=2, tickdirection=:out,
    xlab="x", ylab="y", xlim=(0, 11), ylim=(0, 9))
annotate!(data.x, data.y .+ 0.2, text.(data.z, 8, :blue))
contour!(res["xg"], res["yg"], res["zg"],
    levels=10:5:30, cbar=false, clabels=true, c=:black)

# 2. One-dimensional example, smoothing Absolute Salinity to
# a 1-dbar grid (note: mean(diff(p))=0.24 dbar).
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
ctd = read_ctd_cnv(file);
p = ctd["pressure"];
y = repeat([1], length(p)); # fake y data, with arbitrary value
SA = ctd["SA"];
dp = 1.0;
pg = range(0.0, maximum(p), step=dp);
g = interpolate_barnes(p, y, SA; xg=pg, xr=dp);
plot_profile(ctd, which="SA", seriestype=:scatter)
plot!(g["zg"][:], g["xg"][:], color=:red, label=false)

```

# References

1. Barnes, Stanley L. “Applications of the Barnes Objective Analysis Scheme.
   Part I: Effects of Undersampling, Wave Position, and Station Randomness.”
   Journal of Atmospheric and Oceanic Technology. Journal of Atmospheric and
   Oceanic Technology 11, no. 6 (1994a): 1433–48.

2. Barnes, Stanley L. “Applications of the Barnes Objective Analysis Scheme.
   Part II: Improving Derivative Estimates.” Journal of Atmospheric and Oceanic
   Technology. Journal of Atmospheric and Oceanic Technology 11, no. 6 (1994b):
   1449-1458.

3. Barnes, Stanley L. “Applications of the Barnes Objective Analysis Scheme.
   Part III: Tuning for Minimum Error.” Journal of Atmospheric and Oceanic
   Technology. Journal of Atmospheric and Oceanic Technology 11, no. 6 (1994c):
   1459–79.
"""
function interpolate_barnes(x, y, z; w=nothing, xg=nothing, yg=nothing,
    xr=nothing, yr=nothing, gamma=0.5, iterations=2, debug=0)
    oad(debug, "interpolate_barnes() START")
    # Handle arguments
    nx = length(x)
    nx_distinct = length(unique(x))
    ny = length(y)
    nx == ny || throw(ArgumentError("lengths of x ($nx) and y ($ny) do not match"))
    nz = length(z)
    ny_distinct = length(unique(y))
    nx == nz || throw(ArgumentError("lengths of x ($nx) and y ($nz) do not match"))
    # handle keywords
    if isnothing(w)
        w = repeat([1.0], nx)
    end
    nw = length(w)
    nx == nw || throw(ArgumentError("lengths of x ($nx) and w ($nw) do not match"))
    if isnothing(xg)
        xg = pretty(x, 50)
        oad(debug, "  set xg to ", xg)
    end
    if isnothing(yg)
        yg = pretty(y, 50)
        oad(debug, "  set yg to ", yg)
    end
    nxg = length(xg)
    nyg = length(yg)
    if isnothing(xr)
        e = extrema(y)
        e = extrema(xx for xx in skipmissing(x) if !isnan(xx))
        e = extrema(x)
        xr = (e[2] - e[1]) / sqrt(nx_distinct)
        if xr == 0.0 # catch 1D calls
            xr = 1.0
        end
        oad(debug, "  set xr to ", xr)
    end
    if isnothing(yr)
        e = extrema(y)
        e = extrema(yy for yy in skipmissing(y) if !isnan(yy))
        yr = (e[2] - e[1]) / sqrt(ny_distinct)
        if yr == 0.0 # catch 1D calls
            yr = 1.0
        end
        oad(debug, "  set yr to ", yr)
    end
    xr > 0.0 || throw(ArgumentError("xr must be positive, but it is $xr"))
    yr > 0.0 || throw(ArgumentError("yr must be positive, but it is $yr"))
    xr0 = xr # keep for computing weight matrix at end
    yr0 = yr # keep for computing weight matrix at end
    gamma > 0.0 || throw(ArgumentError("gamma must be positive, but it is $gamma"))
    iterations > 0 || throw(ArgumentError("iteration must be positive, but it is $iteration"))
    # Set up storage
    zz = zeros(nyg, nxg)
    wg = zeros(nyg, nxg)
    zd = zeros(nx)
    z_last = zeros(nx)
    for iter in 1:iterations
        oad(debug, "  Iteration $iter: set xr=$xr and yr=$yr")
        # update grid
        for i in 1:nyg
            for j in 1:nxg
                zz[i, j] = interpolate_barnes_point(xg[j], yg[i], zz[i, j],
                    0,
                    x, y, z, w, z_last,
                    xr, yr)
            end
        end
        # interpolate grid back to data locations
        for k in 1:nx
            zd[k] = interpolate_barnes_point(x[k], y[k], z_last[k],
                0,
                x, y, z, w, z_last, xr, yr)
        end
        for k in 1:nx
            z_last[k] = zd[k]
        end
        # refine search range for next iteration
        xr *= sqrt(gamma)
        yr *= sqrt(gamma)
    end
    for i in 1:nyg
        for j in 1:nxg
            wg[i, j] = weight_barnes(xg[j], yg[i], 0, x, y, w, xr, yr)
        end
    end
    oad(debug, "END interpolate_barnes()")
    Dict("xg" => xg, "yg" => yg, "zg" => zz, "wg" => wg, "zd" => zd,
        "xr" => xr0, "yr" => yr0,
        "gamma" => gamma, "iterations" => iterations)
end
