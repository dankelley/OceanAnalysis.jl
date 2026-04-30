"""
    drop_qc(x::Union{Argo,Ctd}; pattern::String="_qc\$", debug::Int64=0)

Remove quality-control (qc) columns from the `data` of an objec of type
[`Argo`](@ref) or [`Ctd`](@ref). This is required before gridding, because qc
columns in such objects are of a one-byte type.

# Arguments

- `x` either an [`Argo`](@ref) object or a [`Ctd`](@ref) object.

# Keywords

- `pattern` a string that gets converted into a regular expression, so backslashes are required for special characters. The default value has such a backslash, to "protect" the dollar sign.  Note that this default is suitable for [`Argo`](@ref) objects acquired from standard data servers.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Return Value

This returns an object that is identical to `x`, except that any columns with
names that are a regular-expression match to `pattern` are omitted.

# Examples
```jldoctest
using OceanAnalysis
pkgdir = dirname(dirname(pathof(OceanAnalysis)));
f = joinpath(pkgdir, "data", "D4902911_095.nc");
a = read_argo(f);
a2 = drop_qc(a);
size(a.data)[2], size(a2.data)[2]

# output
(15, 9)
```
"""
function drop_qc(x::Union{Argo,Ctd}; pattern::String="_qc\$", debug::Int64=0)
    oad(debug, "drop_qc() START")
    oad(debug, "  pattern: \"$(pattern)\"")
    r = Regex(pattern)
    ncol_old = ncol(x.data)
    data = select(x.data, Not(r))
    ncol_new = ncol(data)
    if x isa Argo
        rval = Argo(x.metadata, data)
        oad(debug, "  dropped $(ncol_old - ncol_new) columns in Argo object")
    else
        rval = Ctd(x.metadata, data)
        oad(debug, "  dropped $(ncol_old - ncol_new) columns in Ctd object")
    end
    oad(debug, "END drop_qc()")
    rval
end

#function handle_qc() end
