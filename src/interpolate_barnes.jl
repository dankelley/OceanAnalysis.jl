using DataFrames, CSV, Test, Plots, Statistics

# Interpolate z(x,y) to get zz at location (xx,yy). This works by a
# weighted-exponential-mean method. When used to predict at a grid point, set
# skip=0. When used to predictio at a data point, set skip to the index of the
# point in question. The efolding scale in the exponential is set by 'xr' and
# 'yr'. Note that the quantity being interpolated is z-z_last.
function interpolate_barnes_point(xx::Float64, yy::Float64, zz::Float64,
    skip::Int64,
    x::Vector{Float64}, y::Vector{Float64}, z::Vector{Float64}, w::Vector{Float64}, z_last::Vector{Float64},
    xr::Float64, yr::Float64)
    sum_w = 0.0
    sum = 0.0
    for k in 1:length(x)
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

# Compute a Barnes weight for a prediction of zz at a location
# (xx, yy), given a field z defined at locations (x,y). The
# efolding scale for the influence function is determined by
# dividing the distance components (dx,dy) by xr and yr.
#
# This function is used at the very end of interpolate_barnes().
function weight_barnes(xx::Float64, yy::Float64,
    skip::Int64,
    x::Vector{Float64}, y::Vector{Float64}, w::Vector{Float64},
    xr::Float64, yr::Float64)
    sum_w = 0.0
    for k in 1:length(x)
        if k != skip
            dx = (xx - x[k]) / xr
            dy = (yy - y[k]) / yr
            sum_w += w[k] * exp(-(dx^2 + dy^2))
            #println("k:$k, sum_w:$sum_w")
        end
    end
    (sum_w > 0.0) ? sum_w : NaN
end

"""
    interpolate_barnes(
        x::Union{AbstractVector,AbstractRange},
        y::Union{AbstractVector,AbstractRange},
        z::Union{AbstractVector,AbstractRange},
        w::Union{AbstractVector,AbstractRange,Nothing}=nothing;
        xg::Union{AbstractVector,AbstractRange,Nothing}=nothing,
        yg::Union{AbstractVector,AbstractRange,Nothing}=nothing,
        xr::Union{Float64,Nothing}=nothing,
        yr::Union{Float64,Nothing}=nothing,
        gamma::Float64=0.5, iterations::Int64=2, debug=0)

Interpolate a two-dimensional field to a grid, using the Barnes method as
described by Barnes (1994a, 1994b, 1994c). The methodology follows
that of the `interp_barnes` function in the R `oce` package.

# Arguments

- `x` Vector of Float64 values for the x coordinate of data points.
- `y` Vector of Float64 values for the z coordinate of data points.
- `z` Vector of Float64 values for the z values at the (x,y) data points.
- `w` Vector of Float64 values for the weights for the data points. If not provided, this defaults to a vector of unit values.

# Keywords

- `xg` Float64 vector giving grid coordinates in the x direction. If not provided, this is computed with `pretty(x,50)`.
- `yg` As `xg` but for the `y` direction.
- `xr` Float64 telling the influence scale in the x direction. If not provided, this defaults to the range of `x` values, divided by the square root of the number of `x` values.
- `yr` As `xr` but for the `y` direction.
- `gamma` Float64 telling the value of gamma to use (0.5 by default).
- `iterations` integer telling how many iterations to perform (2 by default).
- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.


# Examples

```julia
using OceanAnalysis, CSV, DataFrames, Statistics, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "wind.csv")
d = CSV.read(file, DataFrame);
w = repeat([1.0], nrow(d));
xg = range(0.0, 11.0, step=0.2);
yg = range(0.0, 9.0, step=0.2);
res = interpolate_barnes(d.x, d.y, d.z, w; xg=xg, yg=yg, xr=2.0, yr=2.0)
scatter(d.x, d.y, framestyle=:box, label=false, ms=2, tickdirection=:out,
    xlab="x", ylab="y", xlim=(0, 11), ylim=(0, 9))
annotate!(d.x, d.y .+ 0.2, text.(d.z, 7))
contour!(res["xg"], res["yg"], res["zg"],
    levels=10:5:30, cbar=false, clabels=true, c=:black)
```


# References

Barnes, Stanley L. “Applications of the Barnes Objective Analysis Scheme. Part
I: Effects of Undersampling, Wave Position, and Station Randomness.” Journal of
Atmospheric and Oceanic Technology. Journal of Atmospheric and Oceanic
Technology 11, no. 6 (1994a): 1433–48.

Barnes, Stanley L. “Applications of the Barnes Objective Analysis Scheme. Part
II: Improving Derivative Estimates.” Journal of Atmospheric and Oceanic
Technology. Journal of Atmospheric and Oceanic Technology 11, no. 6 (1994b):
1449-1458.

Barnes, Stanley L. “Applications of the Barnes Objective Analysis Scheme. Part
III: Tuning for Minimum Error.” Journal of Atmospheric and Oceanic Technology.
Journal of Atmospheric and Oceanic Technology 11, no. 6 (1994c): 1459–79.


"""
function interpolate_barnes(
    x::Union{AbstractVector,AbstractRange},
    y::Union{AbstractVector,AbstractRange},
    z::Union{AbstractVector,AbstractRange},
    w::Union{AbstractVector,AbstractRange,Nothing}=nothing;
    xg::Union{AbstractVector,AbstractRange,Nothing}=nothing,
    yg::Union{AbstractVector,AbstractRange,Nothing}=nothing,
    xr::Union{Float64,Nothing}=nothing,
    yr::Union{Float64,Nothing}=nothing,
    gamma::Float64=0.5, iterations::Int64=2, debug=0)
    oad(debug, "interpolate_barnes() START")
    # Do some initial checks
    nx = length(x)
    nx == length(y) || error("lengths of x and y do not match")
    nx == length(z) || error("lengths of x and z do not match")
    if isnothing(w)
        w = repeat([1.0], nx)
    end
    nx == length(w) || error("lengths of x and w do not match")
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
        e = extrema(x)
        xr = (e[2] - e[1]) / sqrt(nx)
        oad(debug, "  set xr to ", xr)
    end
    if isnothing(yr)
        e = extrema(y)
        yr = (e[2] - e[1]) / sqrt(nx)
        oad(debug, "  set yr to ", yr)
    end
    xr > 0.0 || error("xr is not a positive value")
    yr > 0.0 || error("xr is not a positive value")
    gamma > 0.0 || error("gamma is not a positive number")
    iterations > 0 || error("iteration is not a positive integer")
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
            wg[i,] = weight_barnes(xg[j], yg[i], 0, x, y, z, xr, yr)
        end
    end
    oad(debug, "END interpolate_barnes()")
    Dict("xg" => xg, "yg" => yg, "zg" => zz, "wg" => wg, "zd" => zd)
end
