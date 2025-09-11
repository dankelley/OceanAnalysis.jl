# Used internally
function increment_debug(debug::Int64=0)
    debug > 0 ? debug + 1 : 0
end

function Base.getindex(oce::OA, name::String)
    #println("Getting data element '$name' from an OA object")
    derived = ["SA", "CT", "sigma0", "spiciness0"]
    if name in names(oce.data)
        return oce.data[:, name]
    elseif name in derived
        println("FIXME: compute derived quantity '", name, "'")
        return SA(oce)
    elseif name in keys(oce.metadata)
        return oce.metadata[name]
    else
        error("no '", name, "' present in or computable for this object")
    end
end

function Base.setindex!(oce::OA, value, name::String)
    #println("Setting data element '$name' in a OA object")
    if name in names(oce.data)
        oce.data[:, name] = value
    elseif name in keys(oce.metadata)
        oce.metadata[name] = value
    else
        error("no '", name, "' present in this object")
    end
    return oce
end



"""
    degree = coordinate_from_string(s::String)

Try to extract a longitude or latitude from a string. If there are two
(space-separated) tokens in the string, the first is taken as the decimal
degrees, and the second as decimal minutes. The goal is to parse hand-entered
strings, which might contain letters like `"W"` and `"S"` (or the same
in lower case) to indicate the hemisphere. Humans are quite good at writing
confusing strings, so this function is not always helpful.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> coordinate_from_string("1.5")
1.5

julia> coordinate_from_string("1 30")
1.5

julia> coordinate_from_string("1S 30")
-1.5

julia> coordinate_from_string("27* 14.072 N")
27.234533333333335

julia> coordinate_from_string("111* 31.440 W")
-111.524
```
"""
function coordinate_from_string(s::String)
    # ** Latitude: 27* 14.072 N
    # ** Longitude: 111* 31.440 W
    sign = occursin(r"[wWsS]", s) ? -1.0 : 1.0
    s = replace(s, r"[nNsSeEwW\*]" => "")
    tokens = split(s)
    if length(tokens) == 1
        return sign * parse(Float64, s)
    elseif length(tokens) == 2
        return sign * (parse(Float64, tokens[1]) + parse(Float64, tokens[2]) / 60.0)
    else
        error("malformed coordinate string \"$s\"")
    end
end



"""
    T90 = T90_from_T68(T68::Float64)

Convert a temperature from the T68 scale to the T90 scale.

See also [`T90_from_T48`](@ref).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> T90_from_T68(10.0)
9.997600575861792
```
"""
T90_from_T68(T48::Float64) = T48 / 1.00024
#T90fromT68(T48::Vector{Float64}) = T48 ./ 1.00024

"""
    T90 = T90_from_T48(T48::Float64)

Convert a temperature from the T48 scale to the T90 scale.

See also [`T90_from_T68`](@ref).

# Examples
```jldoctest
julia> using OceanAnalysis

julia> T90_from_T48(10.0)
9.993641526033752
```
"""
T90_from_T48(T48::Float64) = (T48 - 4.4e-6 * T48 * (100.0 - T48)) / 1.00024
#T90fromT48(T48::Vector{Float64}) = (T48 .- 4.4e-6 .* T48 .* (100.0 .- T48)) ./ 1.00024

"""
    get_element(ctd::Ctd, name::String; debug)

Get an element from an object.
"""
function get_element(o::Ctd, name::String; debug::Int64=0)
    oad(debug, "get_element([Ctd object], name=$name) START")
    # Handle values stored directly in Ctd objects
    nameSymbol = Symbol(name)
    if nameSymbol in fieldnames(Ctd)
        return copy(getproperty(o, nameSymbol))
    end
    # Handle items computable via functions of Ctd objects
    if name == "N2"
        return copy(N2(o))
    end
    # Handle TEOS10 variables
    local SA = gsw_sa_from_sp.(o.salinity, o.pressure, o.longitude, o.latitude) |> fix_gsw_bad_code!
    if name == "SA"
        return copy(SA)
    end
    local CT = gsw_ct_from_t.(SA, o.temperature, o.pressure) |> fix_gsw_bad_code!
    if name == "CT"
        return copy(CT)
    end
    if name == "sigma0"
        return copy(gsw_sigma0.(SA, CT)) |> fix_gsw_bad_code!

    elseif name == "spiciness0"
        return copy(gsw_spiciness0.(SA, CT)) |> fix_gsw_bad_code!

    end
    # The item is not handled, so return an empty result
    return Nothing
end

"""
    pretty(x, n::Int64=5; debug::Int64=0)

Calculate sub-intervals with 125 scaling

This function finds intervals that are multiples of 1, 2 or 5. The results are
useful for contour intervals, because the built-in contour() function
(Reference 1) simply divides the range into equal intervals, so that labelled
contours can be quite ugly.

# Examples
```jldoc
julia> using OceanAnalysis

julia> pretty([22.299, 25.091])
8-element Vector{Float64}:
 22.0
 22.5
 23.0
 23.5
 24.0
 24.5
 25.0
 25.5
```

# References

1. <https://github.com/JuliaGeometry/Contour.jl/blob/daad6eb0b1464dbc7e824bf8384cad54a3b76445/src/Contour.jl#L100>)
"""
function pretty(x, n::Int64=5; debug::Int64=0)
    min, max = extrema(filter(!isnan, x))
    oad(debug, "pretty() got min=$min and max=$max")
    if max == min
        println("pretty() got max=min=$min, so returning empty vector")
        return []
    end
    dx = (max - min) / n
    fac = 10^floor(log10(dx))
    dx0 = dx / fac # dx0 should be between 1 and 10
    if !(1.0 <= dx0 <= 10.0)
        error("dx0 = $dx0 is not between 1.0 and 10.0")
    end
    if 0.0 <= dx0 < 1.5
        dx00 = 1.0
    elseif 1.5 <= dx0 < 3.5
        dx00 = 2.0
    elseif 3.5 <= dx0 < 7.5
        dx00 = 5.0
    else
        dx00 = 10.0
    end
    dxnew = dx00 * fac
    # round() cleans up trailing-digits error
    minnew = round(dxnew * floor(min / dxnew), sigdigits=5)
    maxnew = minnew + dxnew * ceil((max - minnew) / dxnew)
    oad(debug, "fac:$fac, dx:$dx, dxnew:$dxnew, min:$min, minnew:$minnew, max:$max, maxnew:$maxnew")
    rval = collect(range(minnew, maxnew, step=dxnew))
    return rval
end

function oad(debug::Int64=0, args...)
    if debug > 0
        print(repeat("    ", debug - 1))
        for arg in args
            print(arg)
        end
        print("\n")
    end
end

"""
    Change GSW 'missing' values (9.e15) to NaN

A copy is returned, with x unaltered.  See [`fix_gsw_bad_code!`](@ref) for an
in-place version.
"""
function fix_gsw_bad_code(x)
    rval = copy(x)
    bad = rval .> 1e15
    if any(bad)
        rval[bad] .= NaN
    end
    rval
end

"""
    In-place change GSW 'missing' values (9.e15) to NaN

This alters x.  See [`fix_gsw_bad_code`](@ref) for a version that does
not alter x.
"""
function fix_gsw_bad_code!(x)
    bad = x .> 1e15
    if any(bad)
        x[bad] .= NaN
    end
    x
end


