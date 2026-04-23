"""
    drop_qc(argo::Argo; pattern="_qc\$", debug::Int64=0)

Remove quality-control (qc) columns from the `data` of an [Argo] object. This
is required before gridding, because qc columns in such objects are of a
one-byte type.

# Return Value

This returns an `Argo` object that is identical to `argo`, except that any
columns with names matching the pattern specified by `pattern` are omitted.

# Arguments

- `argo` an [Argo] object.

# Keywords

- `pattern` a string that gets converted into a regular expression by calling [Regexp()]. Note that backslashes are required for special characters, as is the case for the default, which means to drop all columns whose names end with `_qc`. This default is suitable for [Argo] objects acquired from standard data servers.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples
```julia
using OceanAnalysis, DataFrames

pkgdir = dirname(dirname(pathof(OceanAnalysis)));
f = joinpath(pkgdir, "data", "D4902911_095.nc");
a = read_argo(f);
a2 = drop_qc(a);

ncol(a.data) # 15
ncol(a2.data) #  9
```
"""
function drop_qc(argo::Argo; pattern="_qc\$", debug::Int64=0)
    oad(debug, "drop_qc() START")
    r = Regex(pattern)
    ncol_old = ncol(argo.data)
    rval = Argo(argo.metadata, select(argo.data, Not(r)))
    ncol_new = ncol(rval.data)
    oad(debug, "  dropped $(ncol_old - ncol_new) columns with names matching pattern $(r)")
    oad(debug, "END drop_qc()")
    rval
end
