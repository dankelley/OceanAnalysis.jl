using GLM, DataFrames, Interpolations

"""
   rms(x)::Float64

Compute the root-mean-square value of vector `x`, after filtering out any NaN values.

"""
function rms(x)::Float64
    filtered = filter(!isnan, x)
    isempty(filtered) && return NaN
    sqrt(mean(abs2, filtered))
end

"""
    MLD_CF_detailed(ctd::Ctd; variable::String="temperature", n::Int=5)

Compute mixed-layer depth according to the Chu and Fan (2010) method; see also
Kelley (2018) for an example. This is a low-level function that is typically
used by [`MLD_CF`](@ref), with the difference being that `MLD_CF_detailed`
returns a Dict with more information than the single number returned by
[`MLD_CF`](@ref).

# Arguments

- `ctd` a [`Ctd`](@ref) object.

# Keywords

- `variable` a String holding the name of the variable to be used in the analysis. The default, `"temperature"`, is traditional and arguably the most sensible in most instances.

- `n` an Integer indicating how many levels to examine below each putative mixed-layer region. Chu and Fan (2010) suggest using a small value for this.

# Return value

`MLD_CF_detailed` returns a Dict that contains scalar entries named
`"MLDindex"` (which is the value returned by `MLD_CF`), and `"MLD"` (the
pressure at that index), along with vector entries named `"E1"` `"E2"`, and
`"E2_over_E1"`, defined as in Kelley (2018), which in turn is based on formulae
provided by Chu and Fan (2010).

# References

Chu, Peter C., and Chenwu Fan. “Optimal Linear Fitting for Objective
Determination of Ocean Mixed Layer Depth from Glider Profiles.” Journal of
Atmospheric and Oceanic Technology 27, no. 11 (2010): 1893–98.
[https://doi.org/10.1175/2010JTECHO804.1](https://doi.org/10.1175/2010JTECHO804.1)

Kelley, Dan E. Oceanographic Analysis with R. Springer-Verlag, 2018.
[https://www.springer.com/us/book/9781493988426](https://www.springer.com/us/book/9781493988426).
"""
function MLD_CF_detailed(ctd::Ctd; variable::String="temperature", n::Int=5)::Dict
    p = ctd["pressure"]
    v = ctd[variable]
    np = length(p)
    np > 5 || error("ctd must have >5 measurement levels, but it has only $np")
    n >= 3 || error("n must be at least 4, but got n=$n")
    kstart = min(3, n)
    ks = kstart:np-n-1
    E1 = fill(NaN, np)
    E2 = fill(NaN, np)
    E2_over_E1 = fill(0.0, np) # nks + n)
    df_vp = DataFrame(v=v, p=p)
    df_p = DataFrame(p=p)
    for k in ks
        above = 1:k
        below = k+1:k+n
        model = lm(@formula(v ~ p), df_vp[above, :])
        vhat = predict(model, df_p)
        E1[k] = rms(v[above] .- vhat[above])
        E2[k] = abs(mean(vhat[below] .- v[below]))
        E2_over_E1[k] = E2[k] / E1[k]
    end
    # replace NaNs for argmax() to work
    replace!(E2_over_E1, NaN => 0.0)
    MLDindex = argmax(E2_over_E1)
    Dict("E1" => E1, "E2" => E2, "E2_over_E1" => E2_over_E1, "MLDindex" => MLDindex, "MLD" => p[MLDindex])
end

"""
    MLD_CF(ctd::Ctd; variable::String="temperature", n::Int=5)::Float64

Compute mixed-layer depth according to the Chu and Fan (2010) method; see also Kelley (2018) for an example. The usual practice is to use `MLD_CF()`, but [`MLD_CF_detailed`](@ref) may be used to investigate the steps in the analysis. An alternative formulation of MLD may be computed with [`MLD_KRH`](@ref).

# Arguments

- `ctd` a [`Ctd`](@ref) object.

# Keywords

- `variable` a String holding the name of the variable to be used in the analysis. The default, `"temperature"`, is traditional and arguably the most sensible in most instances.

- `n` an Integer indicating how many levels to examine below each putative mixed-layer region. Chu and Fan (2010) suggest using a small value for this.

# Return value

`MLD_CF()` returns a single number, which is the index of the pressure vector that is closest to the estimated mixed-layer depth.

# References

Chu, Peter C., and Chenwu Fan. “Optimal Linear Fitting for Objective
Determination of Ocean Mixed Layer Depth from Glider Profiles.” Journal of
Atmospheric and Oceanic Technology 27, no. 11 (2010): 1893–98.
[https://doi.org/10.1175/2010JTECHO804.1](https://doi.org/10.1175/2010JTECHO804.1)

Kelley, Dan E. Oceanographic Analysis with R. Springer-Verlag, 2018.
[https://www.springer.com/us/book/9781493988426](https://www.springer.com/us/book/9781493988426).

# Examples

```julia
using OceanAnalysis, Plots, Printf
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
c = read_ctd_cnv(f);
MLD = MLD_CF(c);
inML = c["pressure"] .< MLD;
pT = scatter(c["temperature"], c["pressure"], group=inML, marker=[:x :cross],
    xlab="Temperature", ylab="Pressure [dbar]", legend=false, yflip=true)
hline!([MLD], color=:red)
title!(@sprintf("MLD %.1f m by Chu-Fanning (2010) method", MLD))
```

"""
function MLD_CF(ctd::Ctd; variable::String="temperature", n::Int=5)::Float64
    MLD_CF_detailed(ctd; variable=variable, n=n)["MLD"]
end


"""
    MLD_KRH(c::Ctd; variable::String="temperature", criterion=0.8)

Compute surface isothermal layer depth (ILD) with the method described by Kara,
Rochford and Hurlburt (2000). An alternative method is used by
[`MLD_CF`](@ref).

**Plans.** Add density-based mixed layer depth (MLD).

# Arguments

- `c` a [`Ctd`] object.

# Keywords

- `variable` a String holding the name of the relevant hydrographic variable. At present, this must be `"temperature"`, but in a later version, "density" may also be permitted.

- `criterion` a number giving the criterion for changes in the designated variable. By default, this is 0.8°C, as suggested by Kara et al. (2000).

# References

Kara, A. Birol, Peter A. Rochford, and Harley E. Hurlburt. “An Optimal
Definition for Ocean Mixed Layer Depth.” Journal of Geophysical Research 105,
no. C7 (2000): 16803–21. https://doi.org/10.1029/2000JC900072.

# Examples
```julia
using OceanAnalysis, Plots, Printf
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
c = read_ctd_cnv(f);
MLD = MLD_KRH(c); # really, it is ILD (isothermal layer depth)
inML = c["pressure"] .< MLD;
pT = scatter(c["temperature"], c["pressure"], group=inML, marker=[:x :cross],
    xlab="Temperature", ylab="Pressure [dbar]", legend=false, yflip=true)
hline!([MLD], color=:red)
title!(@sprintf("MLD %.1f m by Kara-Rochford-Hurlburt (2000) method", MLD))
```
"""
function MLD_KRH(c::Ctd; variable::String="temperature", criterion=0.8)
    variable == "temperature" || throw(ArgumentError("variable must be :temperature, but it is :$variable"))
    p = c.data.pressure
    Interpolations.deduplicate_knots!(p)
    # FIXME: handle "density" as a choice
    T = c[variable]
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
    pstar = itp2.(Tstar)
    #println("pstar: $pstar, Tstar: $Tstar")
    #pstar, Tref, Tstar
    pstar
end
