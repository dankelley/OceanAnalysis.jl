using DSP: Lowpass, Butterworth, digitalfilter, filtfilt
using Statistics: mean
using Dierckx: Spline1D, derivative
using GibbsSeaWater: gsw_ct_from_t, gsw_sigma0

const G_ACCEL = 9.81
const RHO_REF = 1000.0


"""
    N2(ctd::Ctd; method::Symbol=:spline, debug::Integer=0, kwargs...)

A general function to compute the square of the buoyancy frequency, N², for a
[`Ctd`](@ref) object. This works by dispatching to [`N2_spline`](@ref) or to
[`N2_first_difference`](@ref), according as to whether `method` is `:spline` or
`:first_difference`. The `kwargs...` arguments are passed to these lower-level
functions, to control the details of processing.

# Parameters

- `ctd` a [`Ctd`](@ref) object. If `method` is `:first_difference`, then `ctd` must have a uniformly incrementing pressure; see [N2_first_difference()] for details.

- `method` either `:spline` or `:first_difference`; see the documentation of [`N2_spline`](@ref) and [`N2_first_difference`](@ref).

# Keywords

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

- `kwargs` optional items passed by name to [`N2_spline`](@ref) or to [`N2_first_difference`](@ref), depending on the value of `:method`.

# Return value

This function returns a vector of N² values.

# Examples

```julia
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "D4902911_095.nc")
ctd = filename |> read_argo |> drop_qc |> as_ctd;
ctd_gridded = grid_ctd(ctd, pressure_step=1.0);
N2_fd = N2_first_difference(ctd_gridded);
panel_left = plot_profile(ctd, which="sigma0", ylim=(0, 500),
    markersize=1.2)
panel_right = plot_profile(ctd, which="N2", ylim=(0, 500),
    color=:blue, markersize=0, label="Spline method", legend=:bottomright)
plot!(N2_fd, ctd_gridded["pressure"], label="Smoothing method")
plot(panel_left, panel_right, layout=(1, 2))
```
"""
function N2(ctd::Ctd; method::Symbol=:spline, debug::Integer=0, kwargs...)::Vector{Float64}
    oad(debug, "N2() START")
    kw = (; kwargs...)
    oad(debug, "  method: $method")
    if method == :spline
        s = get(kw, :s, :auto)
        bc = get(kw, :bc, "nearest")
        rval = N2_spline(ctd; s=s, bc=bc, debug=increment_debug(debug))
    elseif method == :first_difference
        M = get(kw, :M, 50)
        order = get(kw, :order, 4)
        rval = N2_first_difference(ctd; M=M, order=order, debug=increment_debug(debug))
    else
        throw(ArgumentError("method must be either :spline or :first_difference"))
    end
    oad(debug, "END N2()")
    rval
end
export N2


"""
    N2_spline(ctd::Ctd; s::Union{Float64,Symbol}=:auto, delta::Real=0.025,
        bc::String="nearest", debug::Integer=0)::Vector{Float64}

Compute the square of the buoyancy frequency, N² (in 1/s²), for a [`Ctd`](@ref)
object. The value is inferred from a smoothing cubic spline that models the
pressure-dependence of potential density anomaly, sigma0.

In the present version, the spline is fitted with the `Dierckx::Spline1D()`
function (Reference 1), which is provided with equal weights, `w`, for all
points, with `k=3` to set the polynomial order to cubic, and with the
user-specified `bc` to control behaviour near top and bottom, along with `s`
(and possibly `delta`) to control smoothness.

# Parameters

- `ctd` a [`Ctd`](@ref) object

# Keywords

- `s` either a Float64 value or a symbol. In the first case, it is the value of
  `s` supplied to `Dierckx::Spline1D()`, which is used to smooth the density
  curve as a function of pressure.  According to the documentation for the
  Fortran code behind this function (see
  [https://www.netlib.org/dierckx/curfit.f](https://www.netlib.org/dierckx/curfit.f)),
  a reasonable starting point for exploring the dependence of the spline curve on
  `s` is in the range from ``(n-\\sqrt{2n}) \\delta^2`` to ``(n+\\sqrt{2n})
  \\delta^2``, where ``n`` is the number of data points and ``\\delta`` is a
  measure of the density "wiggles" (anomalies or high-wavenumber signals) to be
  smoothed across in the spline. The midpoint of this range, i.e. ``n\\delta^2``,
  is used if `s=:auto` (the default) is specified. Using `s=:smooth` and
  `s=:rough` multiplies this value by ``\\sqrt{2}`` and ``1/\\sqrt{2}``,
  respectively. (Setting `debug=1` will display the `s` values that are set up in
  these three cases, which may be of help to users who wish to supply `s`
  numerically.)

- `delta` a numeric value used only if `s` has been specified `:auto`,
  `:smooth` or `:rough`. See the discussion of how this is combined with the
  number of data points, to infer a numerical value for `s` in the call to
  `Dierckx::Spline1D()`. The default value of `delta`, 0.025, may be suitable for
  initial exploration, although detailed work normally involves specifying `s` as
  a numerical value, in which case `delta` is ignored.

- `bc` a string, passed to `Dierckx::Spline1D()`, that indicates what to do near boundaries. The default is `"nearest"`.

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# References

1. https://github.com/JuliaMath/Dierckx.jl

# Examples

```julia
# Demonstrate N2_spline()
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
histogram(N2_spline(ctd), label="N²")
```
"""
function N2_spline(ctd::Ctd; s::Union{Float64,Symbol}=:auto, delta::Real=0.025, bc::String="nearest", debug::Integer=0)::Vector{Float64}
    # https://github.com/JuliaMath/Dierckx.jl/blob/dd942e4a38b9ab3288d74177aa36f828a91f56d4/src/Dierckx.jl#L151
    # https://www.netlib.org/dierckx/curfit.f
    # https://juliahub.com/ui/Packages/General/Dierckx/0.5.0
    oad(debug, "N2_spline() START")
    oad(debug, "  s: $s")
    oad(debug, "  bc: $bc")
    pressure::AbstractVector = ctd.data.pressure
    if isa(s, Symbol)
        sorig = s
        if s == :auto
            # According to https://www.netlib.org/dierckx/curfit.f the
            # algorithm adds knots until sum([w_i * (y_i - Y_i)]^2) < s
            # where w_i holds weights, y_i holds data and Y_i holds fits.
            # We call Dierckx.Spline1D() with default weights (i.e. all
            # are set to zero).  The advice is to set $s$ between
            # $N-sqrt(2N)$ and $N+sqrt(2N)4, if $w_i$ is the uncertainty,
            # say $delta_i$, in $y_i$. We will take the middle value
            # as a default if `s=:auto`. Since we are calling `SplineD`
            # with equal weights $w_i=1$, we choose $s=N delta^2$ as
            # the default.
            s = length(pressure) * delta^2
        elseif s == :smooth
            s = 1.414 * length(pressure) * delta^2
        elseif s == :rough
            s = 0.707 * length(pressure) * delta^2
        else
            throw(ArgumentError("if s is a symbol, it must be :auto, :smooth or :rough, not :$s"))
        end
        oad(debug, "  converted s=:$sorig to s=$(round(s,digits=4))")
    else
        oad(debug, "  s=$s on entry")
    end
    SA_ = SA(ctd)
    CT_ = gsw_ct_from_t.(SA_, ctd.data.temperature, ctd.data.pressure)
    sigma0 = gsw_sigma0.(SA_, CT_)
    i = sortperm(pressure)
    ok = vcat(true, diff(pressure[i]) .> 0.0)
    ok = ok .& (0 .== isnan.(sigma0[i]))
    j = i[ok]
    # Perhaps we could let users specify weights, in a future version
    spline::Spline1D = Spline1D(pressure[j], sigma0[j], bc=bc, s=s)
    sigma0p = spline.(pressure)
    rho0 = RHO_REF + mean(sigma0p)
    deriv = derivative(spline, pressure)
    rval = (G_ACCEL / rho0) * deriv
    oad(debug, "END N2_spline()")
    rval
end
export N2_spline



"""
    N2_first_difference(ctd; M::Integer=50, order::Integer=4, debug::Integer=0)::Vector{Float64}

Compute the square of the buoyancy frequency, N² (in 1/s²), based on
first-differences of smoothed density.

# Parameters

- `ctd` a [`Ctd`](@ref) object. This must have pressure values increasing at a
  constant rate; if not, an exception is thrown, with a hint to first use
  [grid_ctd()] to grid the Ctd object.

- `M` cutoff length for Butterworth filter. An exception is thrown if this is
  less than 3.

# Keywords

- `order` integer giving the order of the Butterworth filter. An exception is
  thrown if this is less than 1.

- `debug` an integer indicating whether to print information during processing.
  The default value of 0 means to work quietly, and any larger integer indicates
  to print some information.

# Return value

This function returns a vector of N² values.

# Examples

```julia
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "D4902911_095.nc")
ctd = filename |> read_argo |> drop_qc |> as_ctd;
ctd_gridded = grid_ctd(ctd, pressure_step=1.0);
N2 = N2_first_difference(ctd_gridded);
panel_left = plot_profile(ctd, which="sigma0", ylim=(0, 500), fontsize=7, markersize=1.2)
panel_right = plot_profile(ctd, which="N2", ylim=(0, 500), fontsize=7, color=:blue, markersize=0,
    label="Spline method", legend=:bottomright)
plot!(N2, ctd_gridded["pressure"], label="Smoothing method")
plot(panel_left, panel_right, layout=(1, 2))
```
"""
function N2_first_difference(ctd; M::Integer=50, order::Integer=4, debug::Integer=0)::Vector{Float64}
    oad(debug, "N2_first_difference() START")
    oad(debug, "  M: $M")
    oad(debug, "  order: $order")
    M >= 3 || throw(ArgumentError("M must be 3 or larger, but it is $M"))
    order >= 1 || throw(ArgumentError("order must be 1 or larger, but it is $order"))
    p = ctd["pressure"]
    np = length(p)
    np > M || throw(ArgumentError("Ctd object has only $np levels, so M must be reduced to compute N^2"))
    dp = diff(p)
    all(dp .== dp[1]) || error("non-constant pressure interval prevents digital filtering; use grid_ctd() on the Ctd first")
    response_type = Lowpass(1.0 / M)
    design_method = Butterworth(order)
    filter = digitalfilter(response_type, design_method; fs=1.0 / dp[1])
    sigma0 = ctd["sigma0"]
    sigma0 !== nothing || error("cannot find/compute sigma0 for this Ctd object")
    sigma0_filtered = filtfilt(filter, sigma0)
    # First-difference for derivative. We repeat the top value to match length, and
    # to recognize that the top samples are very likely to be in a well-mixed
    # layer.
    dsigma0_dp = diff(sigma0_filtered) ./ dp
    dsigma0_dp = vcat(dsigma0_dp[1], dsigma0_dp)
    rho0 = RHO_REF + mean(sigma0)
    rval = (G_ACCEL / rho0) * dsigma0_dp
    oad(debug, "END N2_first_difference()")
    rval
end
export N2_first_difference
