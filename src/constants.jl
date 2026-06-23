"""
    GSW_INVALID_THRESHOLD

This value, $(GSW_INVALID_THRESHOLD), is returned by several functions in the
GibbsSeaWater package to indicate an unphysical result of a computation of e.g.
Absolute Salinity, etc. The [`fix_gsw_bad_code`](@ref) and
[`fix_gsw_bad_code!`](@ref) functions provide a convenient way to replace any
such values with NaN.
"""
const GSW_INVALID_THRESHOLD = 1.0e15
export GSW_INVALID_THRESHOLD

"""
    DEFAULT_LONGITUDE

This value, $(DEFAULT_LONGITUDE), is used as a default by [`SA`](@ref), if the
call omits the `longitude` argument.

"""
const DEFAULT_LONGITUDE = -30.0
export DEFAULT_LONGITUDE

"""
    DEFAULT_LATITUDE

This value, $(DEFAULT_LATITUDE), is used as a default by [`SA`](@ref), if the
call omits the `longitude` argument.
"""
const DEFAULT_LATITUDE = 45.0
export DEFAULT_LATITUDE


