using GLM, DataFrames, Interpolations

"""
    ILD_KRH(c::Ctd; criterion=0.8)::Float64

Compute surface isothermal layer depth (ILD) with the method described by Kara et al. (2000). See also [`MLD_KRH`] for an analogous method for finding mixed layer depth (MLD).  An alternative estimate of MLD is provided by [`MLD_CF`](@ref).

# Arguments

- `c` a [`Ctd`] object.

# Keywords

- `criterion` a number giving a criterion for temperature change. The default is 0.8°C, as suggested by Kara et al. (2000).

# References

Kara, A. Birol, Peter A. Rochford, and Harley E. Hurlburt. “An Optimal
Definition for Ocean Mixed Layer Depth.” Journal of Geophysical Research 105,
no. C7 (2000): 16803–21. https://doi.org/10.1029/2000JC900072.

# Examples
```julia
using OceanAnalysis, Plots, Printf
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
c = read_ctd_cnv(f);
ILD = ILD_KRH(c);
plot_profile(c, which="temperature")
hline!([ILD], color=:red)
title!(@sprintf("ILD %.1f m by Kara-Rochford-Hurlburt (2000) method", ILD))
```
"""
function ILD_KRH(c::Ctd; criterion=0.8)::Float64
    p = c.data.pressure
    Interpolations.deduplicate_knots!(p)
    T = c["temperature"]
    # initial estimate for T_ref (may be updated)
    itp = linear_interpolation((p,), T, extrapolation_bc=Flat())
    Tref = itp.(10.0) # initial reference value (may be updated)
    #println("initial Tref: $Tref (interpolated to p=10.0)")
    n = length(T)
    increasing = T[2] > T[1] # may be updated in next loop
    for i in 1:n-1
        if abs(T[i+1] - T[i]) > 0.1 * criterion
            Tref = T[i] # update since we found a ML
            #println("updated Tref: $Tref (at i=$i and p=$(p[i]); note T[i+1]-T[i]=$(T[i+1]-T[i]))")
            increasing = T[i+1] > T[i]
            break
        end
    end
    #println("increasing: $increasing")
    iTb = findfirst(x -> abs(x - Tref) > criterion, T)
    #println("iTb: $iTb")
    #println("below Tdiff: ", T[iTb] - Tref)
    # Interpolate pressure to find where T[i]-Tref == criterion
    ii = iTb .+ [0, -1]
    pp = p[ii]
    TT = T[ii]
    j = sortperm(TT)
    pp = pp[j]
    TT = TT[j]
    #println(DataFrame(i=1:10, p=p[1:10], T=T[1:10]))
    #println("ii: $ii")
    #println("pp: $pp")
    #println("TT: $TT")
    itp2 = linear_interpolation((TT,), pp, extrapolation_bc=Flat())
    #println("Tref-criterion $(Tref-criterion)")
    Tstar = increasing ? Tref + criterion : Tref - criterion
    ILD = itp2.(Tstar)
    #println("ILD: $ILD, Tstar: $Tstar")
    return (ILD)
end
