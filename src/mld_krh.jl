using GLM, DataFrames, Interpolations, GibbsSeaWater

"""
    ILD_KRH(c::Ctd; criterion=0.8)::Float64

Compute surface isothermal layer depth (ILD) with the method described by Kara
et al. (2000). See also [`MLD_KRH`] for an analogous method for finding mixed
layer depth (MLD).  An alternative estimate of MLD is provided by
[`MLD_CF`](@ref).

# Arguments

- `c` a [`Ctd`] object.

# Keywords

- `criterion` a number giving a criterion for temperature change. The default
  is 0.8°C, as suggested by Kara et al. (2000).

# References

1. Kara, A. Birol, Peter A. Rochford, and Harley E. Hurlburt. “An Optimal
   Definition for Ocean Mixed Layer Depth.” Journal of Geophysical Research
   105, no. C7 (2000): 16803–21. https://doi.org/10.1029/2000JC900072.

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
    # The method is basically the same as for MLD_KRH, but for sigma0
    # instead of temperature.  For code similarity, I call the
    # variable "X" in both functions.
    p = c.data.pressure
    Interpolations.deduplicate_knots!(p)
    X = c["temperature"]
    # initial estimate for X_ref (may be updated)
    itp = linear_interpolation((p,), X, extrapolation_bc=Flat())
    Xref = itp.(10.0) # initial reference value (may be updated)
    n = length(X)
    increasing = X[2] > X[1] # may be updated in next loop
    for i in 1:n-1
        if abs(X[i+1] - X[i]) > 0.1 * criterion
            Xref = X[i] # update since we found a ML
            increasing = X[i+1] > X[i]
            break
        end
    end
    iXb = findfirst(x -> abs(x - Xref) > criterion, X)
    # Interpolate pressure to find where X[i]-Xref == criterion
    ii = iXb .+ [0, -1]
    pp = p[ii]
    XX = X[ii]
    j = sortperm(XX)
    pp = pp[j]
    XX = XX[j]
    itp2 = linear_interpolation((XX,), pp, extrapolation_bc=Flat())
    Xstar = increasing ? Xref + criterion : Xref - criterion
    return (itp2.(Xstar))
end

"""
    MLD_KRH(c::Ctd; criterion=0.8)::Float64

Compute surface mixed layer depth (MLD) with the method described by Kara et
al. (2000), although here we use the modern (Gibbs-seawater) density measure
(σ₀) instead of the older measure (σₜ) used by Kara et al. (2000).

An alternative estimate of MLD is provided by [`MLD_CF`](@ref).

See also [`ILD_KRH`](@ref) for an analogous method for finding isothermal layer
depth (ILD).


# Arguments

- `c` a [`Ctd`] object.

# Keywords

- `criterion` a number giving a criterion for temperature change, which is transformed to a density criterion in this function. The default is 0.8°C, as suggested by Kara et al. (2000).

# References

1. Kara, A. Birol, Peter A. Rochford, and Harley E. Hurlburt. “An Optimal
   Definition for Ocean Mixed Layer Depth.” Journal of Geophysical Research
   105, no. C7 (2000): 16803–21. https://doi.org/10.1029/2000JC900072.

# Examples
```julia
using OceanAnalysis, Plots, Printf
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
c = read_ctd_cnv(f);
MLD = MLD_KRH(c);
plot_profile(c, which="temperature")
hline!([MLD], color=:red)
title!(@sprintf("MLD %.1f m by Kara-Rochford-Hurlburt (2000) method", MLD))
```
"""
function MLD_KRH(c::Ctd; criterion=0.8)::Float64
    # The method is basically the same as for ILD_KRH, but for sigma0
    # instead of temperature.  For code similarity, I call the
    # variable "X" in both functions.
    p = c.data.pressure
    Interpolations.deduplicate_knots!(p)
    SA = c["SA"]
    CT = c["CT"]
    X = c["sigma0"]
    #println("original criterion $criterion")
    criterion = gsw_sigma0(SA[1], CT[1]) - gsw_sigma0(SA[1], CT[1] + criterion)
    #println("transformed criterion $criterion (i.t.o. density)")
    # initial estimate for X_ref (may be updated)
    itp = linear_interpolation((p,), X, extrapolation_bc=Flat())
    Xref = itp.(10.0) # initial reference value (may be updated)
    n = length(X)
    increasing = X[2] > X[1] # may be updated in next loop
    for i in 1:n-1
        if abs(X[i+1] - X[i]) > 0.1 * criterion
            Xref = X[i] # update since we found a ML
            #println("updated Xref: $Xref (at i=$i and p=$(p[i]); note X[i+1]-X[i]=$(X[i+1]-X[i]))")
            increasing = X[i+1] > X[i]
            break
        end
    end
    ib = findfirst(x -> abs(x - Xref) > criterion, X)
    #println("ib: $ib")
    # Interpolate pressure to find where X[i]-Xref == criterion
    ii = ib .+ [0, -1]
    pp = p[ii]
    XX = X[ii]
    j = sortperm(XX)
    pp = pp[j]
    XX = XX[j]
    itp2 = linear_interpolation((XX,), pp, extrapolation_bc=Flat())
    Xstar = increasing ? Xref + criterion : Xref - criterion
    return (itp2.(Xstar))
end
