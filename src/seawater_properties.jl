"""
    CT(SA, temperature, pressure)
    CT(ctd)

Compute Conservative Temperature (CT), using `gsw_ct_from_t()` in the
`GibbsSeaWater` package. Note that return values exceeding
$(GSW_INVALID_THRESHOLD) are set to NaN, in accordance with the missing-value
convention used by `GibbSeaWater`.


- Scalar form: takes single values and returns a single value.
- Vector use: the broadcasting convention, i.e. calling as `CT.()` may be used
  if `SA`, `temperature`, and `pressure` are vectors.
- Ctd form: extracts values from the [`Ctd`](@ref) object and then uses
  the vector form.

Units: temperature in °C, pressure in dbar, SA in g/kg.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> CT(35.0, 10.0, 100.0)
9.981322531922249
```
"""
function CT(SA::Real, temperature::Real, pressure::Real)
    rval = gsw_ct_from_t(SA, temperature, pressure)
    if rval >= GSW_INVALID_THRESHOLD
        rval = NaN
    end
    rval
end

function CT(ctd::Ctd)
    if (:CT in propertynames(ctd.data)) || ("CT" in names(ctd.data))
        return copy(ctd.data.CT)
    else
        return CT.(SA(ctd), ctd.data.temperature, ctd.data.pressure)
    end
end


"""
    SA(salinity, pressure, longitude, latitude)
    SA(ctd)

Compute Absolute Salinity (SA), using `gsw_sa_from_sp()` in the `GibbsSeaWater`
package. Note that return values exceeding $(GSW_INVALID_THRESHOLD) are set to
NaN, in accordance with the missing-value convention used by `GibbSeaWater`.

- Scalar form: takes single values and returns a single value.
- Vector use: the broadcasting convention, i.e. calling as `SA.()` may be used
  if `salinity`, `pressure`, `longitude` and `latitude` are vectors.
- Ctd form: extracts values from the [`Ctd`](@ref) object and then uses
  the vector form. (If `ctd.metadata` does not hold `longitude` and
  `latitude`, then they default to $(DEFAULT_LONGITUDE)°E and
  $(DEFAULT_LATITUDE)°N, respectively.)

Units: SA in g/kg, salinity in practical salinity units, pressure in dbar,
longitude in °E and latitude in °N.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> SA(35.0, 100.0, -30.0, 30.0)
35.165308620244
```
"""
function SA(salinity::Real, pressure::Real, longitude::Real=DEFAULT_LONGITUDE, latitude::Real=DEFAULT_LATITUDE)
    #-90.0 <= latitude <= 90.0 || throw(ArgumentError("latitude ($latitude) must be in range from -90 to 90"))
    rval = gsw_sa_from_sp(salinity, pressure, longitude, latitude)
    if rval >= GSW_INVALID_THRESHOLD
        rval = NaN
    end
    rval
end

function SA(ctd::Ctd)
    if (:SA in propertynames(ctd.data)) || ("SA" in names(ctd.data))
        return copy(ctd.data.SA)
    else
        # Ctd objects ought to have salinity and pressure, unless the user has
        # removed them (for some reason that escapes me).
        salinity = ctd.data.salinity
        pressure = ctd.data.pressure
        n = length(pressure)
        n == length(salinity) || error("lengths of salinity and pressure do not match")
        # If metadata stores longitude and latitude as vectors that
        # match e.g. pressure, then use that; otherwise, repeat
        # the first values to construct vectors of length
        # matching pressure.
        lon = get(ctd.metadata, "longitude", DEFAULT_LONGITUDE)
        lat = get(ctd.metadata, "latitude", DEFAULT_LATITUDE)
        longitude = length(lon) == n ? lon : fill(lon[1], n)
        latitude = length(lat) == n ? lat : fill(lat[1], n)
        return SA.(salinity, pressure, longitude, latitude)
    end
end


"""
    salinity_from_conductivity(conductivity::Real, temperature::Real, pressure::Real)

Compute Practical Salinity from electrical conductivity, temperature and
pressure.

Units: conductivity in mS/cm, temperature in °C and pressure in dbar.
"""
function salinity_from_conductivity(conductivity::Real, temperature::Real, pressure::Real)
    gsw_sp_from_c(conductivity, temperature, pressure)
end


"""
    pressure_from_depth(depth::Real, latitude::Real=$(DEFAULT_LATITUDE))

Compute sea pressure from depth and latitude.

Units: pressure in dbar, depth in m and latitude in °N.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> pressure_from_depth(10.0)
10.082069761243858
```
"""
function pressure_from_depth(depth::Real, latitude::Real=DEFAULT_LATITUDE)
    #-90.0 <= latitude <= 90.0 || throw(ArgumentError("latitude ($latitude) must be in range from -90 to 90"))
    return gsw_p_from_z(-depth, latitude, 0.0, 0.0)
end

"""
    pressure_from_z(z::Real, latitude::Real=$(DEFAULT_LATITUDE))

Compute sea pressure from vertical coordinate (height above sea level) and latitude.

Units: pressure in dbar, vertical coordinate in m and latitude in °N.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> pressure_from_z(-10.0)
10.082069761243858
```
"""
function pressure_from_z(z::Real, latitude::Real=DEFAULT_LATITUDE)
    #-90.0 <= latitude <= 90.0 || throw(ArgumentError("latitude ($latitude) must be in range from -90 to 90"))
    return gsw_p_from_z(z, latitude, 0.0, 0.0)
end


"""
    depth_from_pressure(pressure::Real, latitude::Real=$(DEFAULT_LATITUDE))

Compute seawater depth from sea pressure and latitude.

Units: depth in m below the surface, pressure in dbar and latitude in °N.

See also [`z_from_pressure`](@ref).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> depth_from_pressure(100.0)
99.16434938694897
```
"""
function depth_from_pressure(pressure::Real, latitude::Real=DEFAULT_LATITUDE)
    #-90.0 <= latitude <= 90.0 || throw(ArgumentError("latitude ($latitude) must be in range from -90 to 90"))
    return -gsw_z_from_p(pressure, latitude, 0.0, 0.0)
end


"""
    z_from_pressure(pressure::Real, latitude::Real=$(DEFAULT_LATITUDE))

Compute vertical coordinate (height above sea surface) from sea pressure.

Units: coordinate in m above the surface, pressure in dbar and latitude in °N.

See also [`depth_from_pressure`](@ref).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> z_from_pressure(100.0)
-99.16434938694897
```
"""
function z_from_pressure(pressure::Real, latitude::Real=DEFAULT_LATITUDE)
    #-90.0 <= latitude <= 90.0 || throw(ArgumentError("latitude ($latitude) must be in range from -90 to 90"))
    return gsw_z_from_p(pressure, latitude, 0.0, 0.0)
end

