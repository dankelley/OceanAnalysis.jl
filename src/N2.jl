
using DSP, Statistics

"""
    N2(ctd::Ctd; method::Symbol=:spline, debug=0, kwargs...)

General function to compute the square of the buoyancy frequency, N², for a
[`Ctd`](@ref) object. This works by dispatching to [N2_spline()] or to
[N2_first_difference()], according as to whether `method` is `:spline` or
`:first_difference`.

# Parameters

- `ctd` a [Ctd] object. If `method` is `:first_difference`, then `ctd` must have a uniformly incrementing pressure; see [N2_first_difference()] for details.

- `method` either `:spline` or `:first_difference`.

# Keywords

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

- `kwargs` optional items passed by name to either [N2_spline()] or to [N2_first_difference()].

# Return

This function returns a vector of N2 values.

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
function N2(ctd::Ctd; method::Symbol=:spline, debug=0, kwargs...)
    oad(debug, "N2() START")
    kw = (; kwargs...)
    oad(debug, "  method: $method")
    if method == :spline
        s = haskey(kwargs, :s) ? kw[:s] : :auto
        bc = haskey(kwargs, :bc) ? kw[:bc] : "nearest"
        rval = N2_spline(ctd; s=s, bc=bc, debug=increment_debug(debug))
    elseif method == :first_difference
        M = haskey(kwargs, :M) ? kw[:M] : 50
        order = haskey(kwargs, :order) ? kw[:M] : 4
        rval = N2_first_difference(ctd; M=M, order=order, debug=increment_debug(debug))
    else
        error("method must be either :spline or :first_difference")
    end
    oad(debug, "END N2()")
    rval
end


"""
    N2_spline(ctd::Ctd; s::Union{Float64,Symbol}=:auto, bc::String="nearest", debug::Int64=0)

Compute the square of the buoyancy frequency, N², for a [`Ctd`](@ref) object.
The value is inferred from a smoothing cubic spline that models the dependence
of sigma0 on pressure.

In the present version, the spline is fitted with the `Dierckx::Spline1D()`
function (Reference 1), which is provided with equal weights, `w`, for all
points, with `k=3` to set the polynomial order to cubic, and with the
user-specified `bc` to control behaviour near top and bottom, along with `s` to
control smoothness.

# Parameters

- `ctd` a [Ctd] object

# Keywords

- `s` either a Float64 value or a symbol. In the first case, it is the value of  `s` supplied to `Dierckx::Spline1D()`, which is used to smooth the density curve as a function of pressure.  According to the documentation for the Fortran code behind this function (see https://www.netlib.org/dierckx/curfit.f), a reasonable starting point for exploring the dependence of the spline curve on `s` is in the range from `delta^2*(N-sqrt(2N))` to `delta^2*(N+sqrt(2N))`, where `N` is the number of data points and `delta` is a measure of the density "wiggles" across which to smooth the spline. This is the value used if `s=:auto` (the default) is specified; using `s=:smooth` and `s=:rough` multiplies this value by sqrt(2) and 1/sqrt(2), respectively. Note that specifying `debug=1` will make the function print out the numeric value of `s` used, if one of these three symbols has been supplied.

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
function N2_spline(ctd::Ctd; s::Union{Float64,Symbol}=:auto, bc::String="nearest", debug::Int64=0)
    # https://github.com/JuliaMath/Dierckx.jl/blob/dd942e4a38b9ab3288d74177aa36f828a91f56d4/src/Dierckx.jl#L151
    # https://www.netlib.org/dierckx/curfit.f
    # https://juliahub.com/ui/Packages/General/Dierckx/0.5.0
    oad(debug, "N2_spline() START")
    oad(debug, "  s: $s")
    oad(debug, "  bc: $bc")
    pressure = ctd.data.pressure
    if isa(s, Symbol)
        sorig = s
        delta = 0.025 # perhaps reasonable
        new_s = length(pressure) * delta^2
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
            error("If 's' is a symbol, it must be :auto, :smooth or :rough")
        end
        oad(debug, "  converted s=:$sorig to s=$(round(s,digits=4))")
    else
        oad(debug, "  s=$s on entry")
    end
    pressure = ctd.data.pressure
    SA_ = SA(ctd)
    CT_ = gsw_ct_from_t.(SA_, ctd.data.temperature, ctd.data.pressure)
    sigma0 = gsw_sigma0.(SA_, CT_)
    i = sortperm(pressure)
    ok = diff(pressure[i]) .> 0.0
    ok = [ok[1]; ok]
    #oad(debug, "  sum(ok): $(sum(ok)) before considering NaN sigma0")
    ok = ok .& (0 .== isnan.(sigma0[i]))
    #oad(debug, "  sum(ok): $(sum(ok)) after considering NaN sigma0")
    j = i[ok]
    #local spline = Spline1D(pressure[j], sigma0[j], w=ones(sum(ok)), k=3, bc="nearest", s=s)
    # FIXME: let user specify weights?
    local spline = Spline1D(pressure[j], sigma0[j], bc=bc, s=s)
    sigma0p = evaluate(spline, pressure)
    rho0 = 1000.0 + mean(sigma0p)
    #oad(debug, "  rho0: ", round(rho0, digits=3))
    g = 9.8
    deriv = derivative(spline, pressure)
    rval = (g / rho0) * deriv
    #rval = ifelse.(rval .< 0.0, 0.0, rval)
    oad(debug, "END N2_spline()")
    rval
end



"""
    N2_first_difference(ctd; M::Integer=50, order::Integer=4, debug::Integer=0)

Computation of N^2 based on first-differences of smoothed density.

# Parameters

- `ctd` a [Ctd] object. This must have pressure values increasing at a constant rate; if not, an error is reported, with a hint to first use [grid_ctd()] to grid the Ctd object.

- `M` cutoff length for Butterworth filter. An error is reported if this is less than 3.

# Keywords

- `order` integer giving the order of the Butterworth filter. An error is reported if this is less than 1.

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# Return

This function returns a vector of N2 values.

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
function N2_first_difference(ctd; M::Integer=50, order::Integer=4, debug::Integer=0)
    oad(debug, "N2_first_difference() START")
    oad(debug, "  M: $M")
    oad(debug, "  order: $order")
    M >= 3 || error("M must be 3 or larger")
    order >= 1 || error("order must be 1 or larger")
    p = ctd["pressure"]
    np = length(p)
    np > M || error("this Ctd object has ", np, " levels, so M must be reduced to compute N^2")
    dp = diff(p)
    all(dp .== dp[1]) || error("you must use grid_ctd() on the Ctd object first")
    response_type = DSP.Lowpass(1.0 / M)
    design_method = DSP.Butterworth(order)
    filter = DSP.digitalfilter(response_type, design_method; fs=dp[1])
    sigma0 = ctd["sigma0"]
    sigma0 != Nothing || error("cannot find/compute sigma0 for this Ctd object")
    sigma0_filtered = DSP.filtfilt(filter, sigma0)
    #println("\nsigma0:", first(sigma0, 10))
    #println("\nsigma0_filtered:", first(sigma0_filtered, 10))
    # First-difference for derivative (repeat top value to match length)
    dsigma0_dp = diff(sigma0_filtered) ./ dp
    #println("\ndsigma0_dp:", first(dsigma0_dp, 10))
    dsigma0_dp = [dsigma0_dp[1]; dsigma0_dp]
    #println("\ndsigma0_dp:", first(dsigma0_dp, 10))
    g = 9.8
    rho0 = 1000.0 + Statistics.mean(sigma0)
    rval = g / rho0 * dsigma0_dp
    oad(debug, "END N2_first_difference()")
    #println("\nN2:", first(rval, 10))
    rval
end
