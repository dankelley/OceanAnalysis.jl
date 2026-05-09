using OceanAnalysis, Plots, GLM, DataFrames, StatsBase, Plots

"""
    MLD_CF(ctd::Ctd; variable::String="temperature", n::Int64=5, debug::Int64=0)

Compute mixed-layer depth according to the Chu and Fan (2010) method; see also
Kelley (2018) for an example.

# Arguments

- `ctd` a [`Ctd`](@ref) object.

# Keywords

- `variable` a String holding the name of the variable to be used in the analysis. The default, `"temperature"`, is traditional and arguably the most sensible in most instances.

- `n` an Integer indicating how many levels to examine below each putative mixed-layer region. Chu and Fan (2010) suggest using a small value for this, without much more information. However, their Figure 1 suggests the value `n=4`. Here, the default is set at 5, for consistency with Example 5.5 in Kelley (2018). Experimentation with this value is recommended.

- `debug` an integer that controls the form of the return value.

# Return

If `debug=0` (the default) then this returns an integer holding the row of
`ctd` that is closest to the estimated mixed-layer depth. If `debug>0` then
this returns a Dict with scalar entries named `"MLDindex"` (which is the value
returned if `debug=0`), and `"MLD"` (the pressure at that index), along with
vector entries named `"E1"` `"E2"`, and `"E2_over_E1"`, defined as in Kelley
(2018), which in turn is based on formulae provided by Chu and Fan (2010).

## Examples
```juliadoc
using OceanAnalysis
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
c = read_ctd_cnv(f);
MLDindex = MLD_CF(c) # 13
MLD = c["pressure"][MLDindex] # 4.292
```

# References

Chu, Peter C., and Chenwu Fan. “Optimal Linear Fitting for Objective
Determination of Ocean Mixed Layer Depth from Glider Profiles.” Journal of
Atmospheric and Oceanic Technology 27, no. 11 (2010): 1893–98.
[https://doi.org/10.1175/2010JTECHO804.1](https://doi.org/10.1175/2010JTECHO804.1)

Kelley, Dan E. Oceanographic Analysis with R. Springer-Verlag, 2018.
[https://www.springer.com/us/book/9781493988426](https://www.springer.com/us/book/9781493988426).
"""
function MLD_CF(ctd::Ctd; variable::String="temperature", n::Int64=5, debug::Int64=0)
    p = ctd["pressure"]
    v = ctd[variable]
    np = length(p)
    np > 5 || error("MLD_CF() requires ctd to have >5 measurement levels")
    kstart = min(3, n)
    ks = kstart:np-n-1
    nk = length(ks)
    E1 = fill(NaN, np)
    E2 = fill(NaN, np)
    E2_over_E1 = fill(NaN, np)
    for k in ks
        above = 1:k
        below = k+1:k+1+n
        data = DataFrame(v=v[above], p=p[above])
        model = lm(@formula(v ~ p), data)
        vhat = convert(Vector{Float64}, predict(model, DataFrame(p=p)))
        E1[k] = rmsd(v[above], vhat[above])
        E2[k] = abs(mean(vhat[below] .- v[below]))
        E2_over_E1[k] = E2[k] / E1[k]
    end
    E2_over_E1[isnan.(E2_over_E1)] .= 0.0 # since we want argmax() to work
    MLDindex = argmax(E2_over_E1)
    MLD = p[MLDindex]
    if debug > 0
        Dict("E1" => E1, "E2" => E2, "E2_over_E1" => E2_over_E1, "MLDindex" => MLDindex, "MLD" => MLD)
    else
        MLDindex
    end
end

