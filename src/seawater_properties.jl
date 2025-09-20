"""
    CT(SA, temperature, pressure)
    CT(ctd)

Compute Conservative Temperature (CT), using `gsw_ct_from_t()` in the `GibbsSeaWater`
package.

The first form takes single values and returns a single value. The second form
extracts values from a [`Ctd`](@ref) object and then calls the first form as
`CT.()` so that it returns a vector of CT values.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> CT(35.0, 10.0, 100.0)
9.981322531922249
```
"""
function CT(ctd::Ctd)
    if "CT" in names(ctd.data)
        return copy(ctd.data.CT)
    else
        return CT.(SA(ctd), ctd.data.temperature, ctd.data.pressure)
    end
end

function CT(SA::Float64, temperature::Float64, pressure::Float64)
    gsw_ct_from_t(SA, temperature, pressure)
end


"""
    SA(salinity, pressure, longitude, latitude)
    SA(ctd)

Compute Absolute Salinity (SA), using `gsw_sa_from_sp()` in the `GibbsSeaWater`
package.

The first form takes single values and returns a single value. The second form
extracts values from a [`Ctd`](@ref) object and then calls the first form as
`SA.()` so that it returns a vector of SA values.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> SA(35.0, 100.0, -30.0, 30.0)
35.165308620244
```
"""
function SA(ctd::Ctd)
    if "SA" in names(ctd.data)
        return copy(ctd.data.SA)
    else
        salinity = ctd.data.salinity
        pressure = ctd.data.pressure
        n = length(salinity)
        longitude = repeat([ctd.metadata["longitude"]], n)
        latitude = repeat([ctd.metadata["latitude"]], n)
        return SA.(salinity, pressure, longitude, latitude)
    end
end

function SA(salinity::Float64, pressure::Float64,
    longitude::Float64, latitude::Float64)
    #println("SA(): salinity $salinity, pressure $pressure, lon $longitude, lat $latitude")
    rval = gsw_sa_from_sp(salinity, pressure, longitude, latitude)
    if rval > 1e15
        rval = NaN
    end
    #println("  rval $rval")
    rval
end

"""
    N2(ctd::Ctd, s::Float64=0.15; debug::Int64=0)

Compute the square of the buoyancy frequency, N², for a [`Ctd`](@ref) object.
The value is inferred from a smoothing cubic spline that models the dependence
of sigma0 on pressure.

In the present version, the spline is fitted with the `Dierckx::Spline1D()`
function (Reference 1), which is provided with equal weights, `w`, for all
points, with `k=3` to set the polynomial order to cubic, and with
`bc="nearest"` to control what happens near boundaries. The user has no control
over these things, although this might change in a future version of `N2()`.

The user's control rests in `s`, a smoothing parameter that is passed to
`Dierckx:Spline1D()`. If not specified by the user, this defaults to a value
that yields N² curves that are similar to those computed with a default call to
`swN2()` in the `oce` R package.  Users may elect to use larger `s` values for
smoother curves, or smaller ones to get more detail.  It would be a mistake not
to pair experiments with `s` values with plots. As a start, it might be useful
to examine Reference 2, which compares the R and Julia results.

# References

1. https://github.com/JuliaMath/Dierckx.jl
2. https://github.com/dankelley/OceanAnalysis.jl/issues/13

# Examples

```julia
# Demonstrate N2()
using OceanAnalysis, Plots
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "ctd.cnv")
ctd = read_ctd_cnv(filename);
# Basic plot (left), profile-plot in oceanographic convention (right)
p1=plot(N2(ctd), z_from_pressure.(ctd.data.pressure))
p2=plot_profile(ctd, which="N2")
plot(p1, p2)
```
"""
function N2(ctd::Ctd, s::Float64=0.15; debug::Int64=0)
    oad(debug, "N2([Ctd object]) START")
    pressure = ctd.data.pressure
    SA_ = SA(ctd)
    CT_ = gsw_ct_from_t.(SA_, ctd.data.temperature, ctd.data.pressure)
    sigma0 = gsw_sigma0.(SA_, CT_)
    i = sortperm(pressure)
    ok = diff(pressure[i]) .> 0.0
    ok = [ok[1]; ok]
    oad(debug, "    ok length: $(length(ok))")
    j = i[ok]
    local spline = Spline1D(pressure[j], sigma0[j], w=ones(sum(ok)), k=3, bc="nearest", s=s)
    sigma0p = evaluate(spline, pressure)
    rho0 = 1000.0 + mean(sigma0p)
    g = 9.8
    deriv = derivative(spline, pressure)
    N2 = (g / rho0) * deriv
    oad(debug, "    N2 length: ", length(N2))
    oad(debug, "END N2()")
    return N2
end



"""
    Compute Practical Salinity from conductivity (mS/cm), temperature (degC) and pressure (dbar).
"""
#gsw::gsw_SP_from_C(C0 * conductivity, temperature, pressure)
function salinity_from_conductivity(conductivity::Float64, temperature::Float64, pressure::Float64)
    gsw_sp_from_c(conductivity, temperature, pressure)
end


"""
    Compute sea pressure (dbar) from depth (m) and latitude (deg).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> pressure_from_depth(10.0)
10.082069761243858
```
"""
function pressure_from_depth(depth::Float64, latitude::Float64=45.0)
    return gsw_p_from_z(-depth, latitude, 0.0, 0.0)
end

"""
    Compute sea pressure (dbar) from vertical coordinate (m) and latitude (deg).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> pressure_from_z(-10.0)
10.082069761243858
```
"""
function pressure_from_z(z::Float64, latitude::Float64=45.0)
    return gsw_p_from_z(z, latitude, 0.0, 0.0)
end

"""
    Compute seawater depth (m) from sea pressure (dbar)

See also [`z_from_pressure`](@ref).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> depth_from_pressure(100.0)
99.16434938694897
```
"""
function depth_from_pressure(pressure::Float64, latitude::Float64=45.0)
    return -gsw_z_from_p(pressure, latitude, 0.0, 0.0)
end

"""
    Compute vertical coordinate (m) from sea pressure (dbar)

See also [`depth_from_pressure`](@ref).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> z_from_pressure(100.0)
-99.16434938694897
```
"""
function z_from_pressure(pressure::Float64, latitude::Float64=45.0)
    return gsw_z_from_p(pressure, latitude, 0.0, 0.0)
end


