"""
    geod_distance(lon1, lat1, lon2, lat2; a=6378137.00, f=1.0 / 298.257223563)

Return the geodetic distance between two points on earth, in kilometres.

This uses the Vincenty [1975] formulation. According to tests described in that
paper, the results can be expected to be accurate to 0.01 mm.

Note that `geod_distance()` mimics the `geodDist()` function in the `oce` R
package (Ref. 2), and is based on the R and C++ code used in the latter. The
code trail is 5 decades long, starting with a CDC-6600 Fortran version written
in 1974 by L. Pfeifer, which was modified for IBM 360 by J. G. Gergen. In 2003,
D. Gillis wrote an R version that was modified for inclusion in the `oce`
package by Dan Kelley.

# Arguments
- `lon1` and `lat1`, in degrees, give the location of a given point on the earth
- `lon2` and `lat2`, in degrees, give the location of a given point on the earth
- `a` and `f` are the semi-major axis and flattening parameter of the reference
ellipsoid. (The default values are highly recommended.)

# References

1. Vincenty,T. 1975. Direct and inverse solutions of geodesics on the ellipsoid
   with application of nested equations. Survey Review 23(176):88-94.
   <https://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf>

2. Kelley, Dan E., Clark Richards, and Chantelle Layton. “Oce: An R Package for
   Oceanographic Analysis.” Journal of Open Source Software 7, no. 71 (2022).
   <https://doi.org/10.21105/joss.03594>
"""
function geod_distance(lon1::Real, lat1::Real, lon2::Real, lat2::Real; a::Real=6378137.00, f::Real=1.0 / 298.257223563)
    # See git/oce/R/geod.R and git/oce/src/geod.cpp; the following code is a Julia
    # version of the C code in the latter file.
    eps = 0.5e-13 # a tolerance parameter for the iterative solution
    r = 1.0 - f
    if ((lat1) == (lat2)) && ((lon1) == (lon2))
        return 0.0
    end
    # Put longitude between 0 and360, in case we are given e.g. -30 go mean 30W.
    if lon1 < 0.0
        lon1 += 360.0
    end
    if lon2 < 0.0
        lon2 += 360.0
    end
    # Convert to radians
    lat1 = lat1 * pi / 180.0
    lon1 = lon1 * pi / 180.0
    lat2 = lat2 * pi / 180.0
    lon2 = lon2 * pi / 180.0
    # The actual formulae
    tu1 = r * sin(lat1) / cos(lat1)
    tu2 = r * sin(lat2) / cos(lat2)
    cu1 = 1.0 / sqrt(tu1 * tu1 + 1.0)
    su1 = cu1 * tu1
    cu2 = 1.0 / sqrt(tu2 * tu2 + 1.0)
    s = cu1 * cu2
    baz = s * tu2
    faz = baz * tu1
    x = lon2 - lon1
    e = sx = sy = cx = c2a = cy = cz = y = 0.0
    for _ in 1:10
        sx = sin(x)
        cx = cos(x)
        tu1 = cu2 * sx
        tu2 = baz - su1 * cu2 * cx
        sy = sqrt(tu1 * tu1 + tu2 * tu2)
        cy = s * cx + faz
        y = atan(sy, cy)
        sa = s * sx / sy
        c2a = -sa * sa + 1.0
        cz = 2.0 * faz
        if c2a > 0.0
            cz = -cz / c2a + cy
        end
        e = cz * cz * 2.0 - 1.0
        c = ((-3.0 * c2a + 4.0) * f + 4.0) * c2a * f / 16.0
        d = x
        x = ((e * cy * c + cz) * sy * c + y) * sa
        x = (1.0 - c) * x * f + lon2 - lon1
        if abs(d - x) < eps # break out from loop if convergence has been achieved
            break
        end
    end
    x = sqrt((1.0 / r / r - 1.0) * c2a + 1.0) + 1.0
    x = (x - 2.0) / x
    c = 1.0 - x
    c = (x * x / 4.0 + 1.0) / c
    d = (0.375 * x * x - 1.0) * x
    x = e * cy
    s = 1.0 - e - e
    s = ((((sy * sy * 4.0 - 3.0) * s * cz * d / 6.0 - x) * d / 4.0 + cz) * sy * d + y) * c * a * r
    return s / 1000.0
end
