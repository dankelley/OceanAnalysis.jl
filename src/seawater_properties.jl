const GSW_INVALID_THRESHOLD = 1.0e15

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
    if (:CT in propertynames(ctd.data)) || ("CT" in names(ctd.data))
        return copy(ctd.data.CT)
    else
        return CT.(SA(ctd), ctd.data.temperature, ctd.data.pressure)
    end
end

function CT(SA::Real, temperature::Real, pressure::Real)
    gsw_ct_from_t(SA, temperature, pressure)
end


"""
    SA(salinity, pressure, longitude, latitude)
    SA(ctd)

Compute Absolute Salinity (SA), using `gsw_sa_from_sp()` in the `GibbsSeaWater`
package.

The first form takes single values and returns a single value, so it
should be called with broadcasting, if the arguments are vectors.

The second form extracts values from the provided [`Ctd`](@ref) object and then
calls the first form as `SA.()`. Note that if the object does not contain
longitude and latitude in its `metadata`, then default values of -30.0 and 45.0
will be used, to represent a mid-Atlantic point.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> SA(35.0, 100.0, -30.0, 30.0)
35.165308620244
```
"""
function SA(ctd::Ctd)
    if (:SA in propertynames(ctd.data)) || ("SA" in names(ctd.data))
        return copy(ctd.data.SA)
    else
        salinity = ctd.data.salinity
        pressure = ctd.data.pressure
        n = length(salinity)
        lon = get(ctd.metadata, "longitude", -30.0)
        lat = get(ctd.metadata, "latitude", 45.0)
        longitude = fill(lon, n)
        latitude = fill(lat, n)
        return SA.(salinity, pressure, longitude, latitude)
    end
end

function SA(salinity::Real, pressure::Real,
    longitude::Real, latitude::Real)
    #println("SA(): salinity $salinity, pressure $pressure, lon $longitude, lat $latitude")
    rval = gsw_sa_from_sp(salinity, pressure, longitude, latitude)
    if rval > GSW_INVALID_THRESHOLD
        rval = NaN
    end
    #println("  rval $rval")
    rval
end


"""
    Compute Practical Salinity from conductivity (mS/cm), temperature (degC) and pressure (dbar).
"""
#gsw::gsw_SP_from_C(C0 * conductivity, temperature, pressure)
function salinity_from_conductivity(conductivity::Real, temperature::Real, pressure::Real)
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
function pressure_from_depth(depth::Real, latitude::Real=45.0)
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
function pressure_from_z(z::Real, latitude::Real=45.0)
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
function depth_from_pressure(pressure::Real, latitude::Real=45.0)
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
function z_from_pressure(pressure::Real, latitude::Real=45.0)
    return gsw_z_from_p(pressure, latitude, 0.0, 0.0)
end

