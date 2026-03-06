# https://github.com/JuliaMath/Dierckx.jl/blob/dd942e4a38b9ab3288d74177aa36f828a91f56d4/src/Dierckx.jl#L151
# https://www.netlib.org/dierckx/curfit.f

"""
    N2(ctd::Ctd, s::Float64=0.15; debug::Int64=0)

Compute the square of the buoyancy frequency, N², for a [`Ctd`](@ref) object.
The value is inferred from a smoothing cubic spline that models the dependence
of sigma0 on pressure.

In the present version, the spline is fitted with the `Dierckx::Spline1D()`
function (Reference 1), which is provided with equal weights, `w`, for all
points, with `k=3` to set the polynomial order to cubic, and with the
user-specified `bc` to control behaviour near top and bottom, along with `s` to
control smoothness.  After the derivative is computed, any negative N² values
are set to zero.

# Parameters

- `ctd` a [Ctd] object

# Keywords

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.
- `s` a numerical value, passed to `Dierckx::Spline1D()`, to control smoothing.
- `bc` a string, passed to `Dierckx::Spline1D()`, that indicates what to do near boundaries. The default is `"nearest"`.

# References

1. https://github.com/JuliaMath/Dierckx.jl

# Examples

```julia
# Demonstrate N2()
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
p1=plot_profile(ctd, which="sigma0")
p2=plot_profile(ctd, which="N2")
plot(p1, p2)
```
"""
function N2(ctd::Ctd; s::Float64=0.10, bc::String="nearest", debug::Int64=0)
    oad(debug, "N2([Ctd object]) START")
    pressure = ctd.data.pressure
    SA_ = SA(ctd)
    CT_ = gsw_ct_from_t.(SA_, ctd.data.temperature, ctd.data.pressure)
    sigma0 = gsw_sigma0.(SA_, CT_)
    i = sortperm(pressure)
    ok = diff(pressure[i]) .> 0.0
    ok = [ok[1]; ok]
    oad(debug, "    sum(ok): $(sum(ok)) before considering NaN sigma0")
    ok = ok .& (0 .== isnan.(sigma0[i]))
    oad(debug, "    sum(ok): $(sum(ok)) after considering NaN sigma0")
    j = i[ok]
    #local spline = Spline1D(pressure[j], sigma0[j], w=ones(sum(ok)), k=3, bc="nearest", s=s)
    # FIXME: let user specify weights?
    local spline = Spline1D(pressure[j], sigma0[j], bc=bc, s=s)
    sigma0p = evaluate(spline, pressure)
    rho0 = 1000.0 + mean(sigma0p)
    oad(debug, "    rho0: ", rho0)
    g = 9.8
    deriv = derivative(spline, pressure)
    N2 = (g / rho0) * deriv
    N2 = ifelse.(N2 .< 0.0, 0.0, N2)
    oad(debug, "END N2()")
    return N2
end

