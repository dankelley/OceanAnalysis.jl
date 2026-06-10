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

An alternative estimate of MLD is provided by [`MLD_KRH`](@ref); its cousin,
[`ILD_KRH`](@ref) is also worthy of consideration.

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
plot_profile(c, which="temperature")
hline!([MLD], color=:red)
title!(@sprintf("MLD %.1f m by Chu-Fanning (2010) method", MLD))
```

"""
function MLD_CF(ctd::Ctd; variable::String="temperature", n::Int=5)::Float64
    MLD_CF_detailed(ctd; variable=variable, n=n)["MLD"]
end
