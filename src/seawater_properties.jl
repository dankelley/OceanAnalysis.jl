"""
    CT(SA, temperature, pressure)
    CT(ctd)

Compute Conservative Temperature (CT), using `gsw_ct_from_t()` in the
`GibbsSeaWater` package.

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

