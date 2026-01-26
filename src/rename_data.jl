"""
    rename_data(names)

Rename data items from labels used in files to names used in code.

# Arguments

- `names` a String holding a name to be converted, or a vector of such strings.

- `number_replicates` a Bool value indicating whether to prevent duplicated names by appending numbers to duplicates.  This is true by default. For example, the first salinity would be named `salinity`, while the second would be named `salinity2`.

# Return value

A String or vector of String items, holding new names.  If any of the converted names appear more than once, then digits are appended (see last example).

# Examples

```julia
using OceanAnalysis
rename_data("CTDPRS")
rename_data(["CTDPRS", "CTDTMP"])
rename_data(["CTDPRS", "CTDTMP", "CTDTMP_FLAG"])
```

"""
function rename_data(names::Union{String,Vector{String}}; number_replicates::Bool=true)
    # Make names a vector, to simplify things. This is undone at the end.
    if !(names isa Vector)
        names = [names]
    end
    rval = replace.(names,
        "CTDPRS" => "pressure",
        "CTDTMP" => "temperature",
        "CTDSAL" => "salinity",
        "CTDOXY" => "oxygen",
        "PSAL" => "salinity",
        "PRES" => "pressure",
        "TEMP" => "temperature",
        "_FLAG_W" => "_flag",
        "_FLAG" => "_flag")
    # Optionally, handle replicates
    if number_replicates && length(rval) > 1
        tally = Dict{String,Int}()
        RVAL = String[]
        for s in rval
            if haskey(tally, s)
                tally[s] += 1
                push!(RVAL, "$(s)$(tally[s])")
            else
                tally[s] = 1
                push!(RVAL, s)
            end
        end
        rval = RVAL
    end
    # return a String, if a String given (i.e. remove vectorization, if done here)
    if length(rval) == 1
        rval = rval[1]
    end
    rval
end
