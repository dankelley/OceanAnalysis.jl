"""
    subset_ctd(ctd::Ctd, keep_levels::Union{BitVector,Vector{Bool}}; debug::Int64=0)

Subset a CTD object by levels.

This returns a copy of `Ctd` that has the same `metadata`,
but for which the `data` holds only rows specified by
the logical vector `keep_levels`.

# Examples

```julia
using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
"D4902911_095.nc")
argo = read_argo(f)
ctd = as_ctd(argo)
a = plot_TS(ctd, title="Original")
ctd_top = subset_ctd(ctd, ctd["pressure"] .< 300)
b = plot_TS(ctd)
plot(a, b, title="Top 300m")
```
"""
function subset_ctd(ctd::Ctd, keep_levels::Union{BitVector,Vector{Bool}}; debug::Int64=0)
    oad(debug, "subset_ctd() START")
    length(keep_levels) == nrow(ctd.data) || throw(ArgumentError("length(keep_levels)=$(length(keep_levels)) differs from nrows(ctd.data)=$(nrows(ctd.data))"))
    oad(debug, "  retaining $(sum(keep_levels)) of $(length(keep_levels)) levels")
    data = copy(ctd.data)
    data = data[keep_levels, :]
    rval = Ctd(ctd.metadata, data)
    oad(debug, "END subset_ctd()")
    rval
end

"""
    subset_ctd!(ctd::Ctd, keep_levels::Union{BitVector,Vector{Bool}}; debug::Int64=0)

This works in the same way as subset_ctd(<Ctd>), except that
the original Ctd is altered in-place.

# Examples

```julia
using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
"D4902911_095.nc")
argo = read_argo(f)
ctd = as_ctd(argo)
a = plot_TS(ctd, title="Original")
subset_ctd!(ctd, ctd["pressure"] .< 300)
b = plot_TS(ctd, title="Original (altered)")
plot(a, b)
```

"""
function subset_ctd!(ctd::Ctd, keep_levels::Union{BitVector,Vector{Bool}}; debug::Int64=0)
    oad(debug, "subset_ctd() START")
    length(keep_levels) == nrow(ctd.data) || throw(ArgumentError("length(keep_levels)=$(length(keep_levels)) differs from nrows(ctd.data)=$(nrows(ctd.data))"))
    oad(debug, "  retaining $(sum(keep_levels)) of $(length(keep_levels)) levels")
    ctd.data = ctd.data[keep_levels, :]
    oad(debug, "END subset_ctd()")
    ctd
end

