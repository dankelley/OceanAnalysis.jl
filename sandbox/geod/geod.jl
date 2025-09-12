function geoddist(lat1::Float64, lon1::Float64, lat2::Float64, lon2::Float64,
    a::Float64=6378137.00, f::Float64=1.0 / 298.257223563)
    #faz::Float64, baz::Float64, s::Float64)
    # See git/oce/R/geod.R and git/oce/src/geod.cpp; the following is founded on the latter

    # Solution of the geodetic inverse problem according to [^1].
    #
    #     lat and lon = conventional, in degrees
    #
    #     a = semi-major axis of the reference ellipsoid.
    #
    #     f = flattening of the ref ellipsoid.
    #
    #     - Programmed for cdc-6600 by LCdr L.Pfeifer NGS Rockville MD 18feb75
    #     - Modified for ibm system 360 by john g gergen ngs rockville md 7507
    #     - Modified for R by D.Gillis Zoology University of Manitoba 16JUN03.
    #     - Translated from fortran to C by Dan Kelley, Dalhousie University 2009-04.
    #
    #     [1]: Vincenty,T. 1975. Direct and inverse solutions of
    #     geodesics on the ellipsoid with application of nested
    #     equations. Survey Review 23(176):88-94.
    #     */

    eps = 0.5e-13
    rpd = pi / 180.0 #/ radians per degree
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

    glat1 = lat1 * rpd
    glon1 = lon1 * rpd
    glat2 = lat2 * rpd
    glon2 = lon2 * rpd

    tu1 = r * sin(glat1) / cos(glat1)
    tu2 = r * sin(glat2) / cos(glat2)
    cu1 = 1.0 / sqrt(tu1 * tu1 + 1.0)
    su1 = cu1 * tu1
    cu2 = 1.0 / sqrt(tu2 * tu2 + 1.0)
    s = cu1 * cu2
    baz = s * tu2
    faz = baz * tu1
    x = glon2 - glon1
    sx = 0.0
    sy = 0.0
    e = 0.0
    cx = 0.0
    c2a = 0.0
    cy = 0.0
    cz = 0.0
    y = 0.0
    for iter in 1:10
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
        x = (1.0 - c) * x * f + lon2 - glon1
        println("iter=", iter, ", abs(d-x)=", abs(d - x))
        if abs(d - x) < eps
            println("early break at iter=", iter, ", since ", abs(d - x), " < eps=", eps)
            break
        end
    end
    #faz = atan(tu1, tu2)
    #baz = atan(cu1 * sx, baz * cx - su1 * cu2) + pi
    x = sqrt((1.0 / r / r - 1.0) * c2a + 1.0) + 1.0
    x = (x - 2.0) / x
    c = 1.0 - x
    c = (x * x / 4.0 + 1.0) / c
    d = (0.375 * x * x - 1.0) * x
    x = e * cy
    s = 1.0 - e - e
    s = ((((sy * sy * 4.0 - 3.0) * s * cz * d / 6.0 - x) * d / 4.0 + cz) * sy * d + y) * c * a * r
    #faz = faz / rpd
    #baz = baz / rpd
    return s
end
@time d = geoddist(45.0, 0.0, 46.0, 0.0)
@time d = geoddist(45.0, 0.0, 46.0, 0.0)
println(d)
