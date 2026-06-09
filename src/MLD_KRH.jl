using Interpolations, DataFrames
"""
    MLD_KRH(c::Ctd; variable::String="temperature", criterion=0.8)

This computes mixed-layer depth according to the Kara et al. (2000) method

# Arguments

- `c` a [`Ctd`] object.

# Keywords

- `variable` a String holding the variable. In the present version, this must
be `"temperature"`.

- `criterion` a number giving the criterion for changes in that variable. By
default, this is the value suggested by Kara et al. (2000), namely of 0.8°C.

# References

Kara, A. Birol, Peter A. Rochford, and Harley E. Hurlburt. “An Optimal
Definition for Ocean Mixed Layer Depth.” Journal of Geophysical Research 105,
no. C7 (2000): 16803–21. https://doi.org/10.1029/2000JC900072.

"""
function MLD_KRH(c::Ctd; variable::String="temperature", criterion=0.8)
    variable == "temperature" || throw(ArgumentError("variable must be :temperature, but it is :$variable"))
    p = c.data.pressure
    Interpolations.deduplicate_knots!(p)
    T = c[variable] # naming T, Tref, Tb, etc to match KRH notation
    # initial estimate for T_ref (may be updated)
    itp = linear_interpolation((p,), T, extrapolation_bc=Flat())
    Tref = itp.(10.0) # initial reference value (may be updated)
    println("initial Tref: $Tref (interpolated to p=10.0)")
    n = length(T)
    increasing = T[2] > T[1] # may be updated in next loop
    for i in 1:n-1
        if abs(T[i+1] - T[i]) > 0.1 * criterion
            Tref = T[i] # update since we found a ML
            println("updated Tref: $Tref (at i=$i and p=$(p[i]); note T[i+1]-T[i]=$(T[i+1]-T[i]))")
            # FIXME: next seems brittle to me, but it's what KRH do
            increasing = T[i+1] > T[i]
            break
        end
    end
    println("increasing: $increasing")
    iTb = findfirst(x -> abs(x - Tref) > criterion, T)
    println("iTb: $iTb")
    println("below Tdiff: ", T[iTb] - Tref)
    # Interpolate pressure to find where T[i]-Tref == criterion
    ii = iTb .+ [0, -1]
    pp = p[ii]
    TT = T[ii]
    println(DataFrame(i=1:10, p=p[1:10], T=T[1:10]))
    println("ii: $ii")
    println("pp: $pp")
    println("TT: $TT")
    itp2 = linear_interpolation((TT,), pp, extrapolation_bc=Flat())
    println("Tref-criterion $(Tref-criterion)")
    Tstar = increasing ? Tref + criterion : Tref - criterion
    pstar = itp2.(Tstar)
    println("pstar: $pstar, Tstar: $Tstar")
    pstar, Tref, Tstar
end
