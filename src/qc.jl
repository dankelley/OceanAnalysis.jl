"""
    drop_qc(ctd::Ctd; pattern="_qc\$", debug::Int64=0)

Remove quality-control columns from the `data` of a Ctd object.  This is
required before gridding, for example, because those columns are encoded
as Char values.

# Return Value

This returns a `Ctd` object that is identical to the input `ctd` value, except
that any columns with names matching the pattern specified by `pattern` are omitted.

# Arguments

- `ctd` a [Ctd] object.

# Keywords

- `pattern` a string that gets converted into a regular expression by calling [Regexp()]. Note that backslashes are required for special characters, as is the case for the default, which means to drop all columns whose names end with `_qc`. This default is suitable for [Ctd] objects created from [Argo] objects using [as_ctd()].

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.
"""
function drop_qc(ctd::Ctd; pattern="_qc\$", debug::Int64=0)
    oad(debug, "drop_qc(Ctd) START")
    r = Regex(pattern)
    ncol_old = ncol(ctd.data)
    rval = Ctd(ctd.metadata, select(ctd.data, Not(r)))
    ncol_new = ncol(rval.data)
    oad(debug, "  dropped $(ncol_old - ncol_new) columns with names matching pattern $(r)")
    oad(debug, "END drop_qc(Ctd)")
    rval
end
