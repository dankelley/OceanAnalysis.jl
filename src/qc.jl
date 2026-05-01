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

"""
    handle_qc(x::Union{Argo,Ctd}; retain::Union{String,Vector{String}}="1", debug::Int64=0)

Handle quality-control flags in [`Argo`](@ref) or [`Ctd`](@ref) object `x`, by setting to NaN any variable entries that have matching qc flag not contained in `retain`.  The flag for a variable named e.g. `salinity` is named `salinity_qc`.  Any variable with no matching qc entries is left unaltered.

This is mainly useful for [`Argo`](@ref) data, but can also be applied in the same way for [`Ctd`](@ref) objects created with [`as_ctd`](@ref).

The Argo coding scheme is described in many online documents (e.g. Section 6.1 of Reference 1). Briefly, `"0"` means that "no QC was performed", `"1"` means "good data", `"2"` means "probably good data", `"3"` means "probably bad data", `"4"` means "bad data", `"5"` means "changed data", `"8"` means "estimated value" and `"9"` means "missing value".

# Arguments
- x an object of type [`Argo`](@ref) or [`Ctd`](@ref).

# Keywords
- `retain` a String, or a vector of Strings, holding the quality-control flags that are considered to reflect acceptable data. The default, `"1"` means to retain only data designated "Good" in the Argo system; this is a safe choice.
- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# References

1. Wong, Annie, Robert Keeley, Thierry Carval, and Argo Data Management Team.
   Argo Quality Control Manual for CTD and Trajectory Data. Version 3.9.
   Ifremer, 2025. https://doi.org/10.13155/33951.
"""
function handle_qc(x::Union{Argo,Ctd}; retain::Union{String,Vector{String}}="1", debug::Int64=0)
    oad(debug, "handle_qc($(typeof(x)), retain=$retain) START")
    rval = x
    retain_set = Set(retain)
    data_names = names(x.data)
    for name in data_names
        #println("name: $name")
        name_qc = name * "_qc"
        #println("name_qc: $name_qc")
        found = name_qc .== data_names
        #println("found: $found")
        fa = findall(found)
        #println("fa: $fa")
        if length(fa) == 1
            n = length(x.data[!, name])
            bad = .!(in.(x.data[!, name_qc], Ref(retain_set)))
            if sum(bad) > 0
                oad(debug, "  $name: setting $(sum(bad)) of the $n values to NaN")
                rval.data[!, name][bad] .= NaN
                #else
                #    oad(debug, "  $name: all values considered acceptable")
            end
        end
    end
    oad(debug, "END handle_qc()")
    rval
end

