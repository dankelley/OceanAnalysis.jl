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
rename_data("CTDPRS") #"pressure"

rename_data(["CTDPRS", "CTDTMP"]) # 2-element Vector{String}: "pressure" "temperature"

rename_data(["CTDPRS", "CTDTMP", "CTDTMP_FLAG"]) # 3-element Vector{String}: "pressure" "temperature" "temperature_flag"
```

"""
function rename_data(names::Union{String,Vector{String}}; number_replicates::Bool=true)::Vector{String}
    # FIXME: add new items to the following
    rval = replace.(names,
        "CTDPRS" => "pressure",
        "CTDTMP" => "temperature",
        "CTDSAL" => "salinity",
        "CTDOXY" => "oxygen",
        "JULD" => "time",
        "DOXY" => "oxygen",
        "LATITUDE" => "latitude",
        "LONGITUDE" => "longitude",
        "PRES" => "pressure",
        "PSAL" => "salinity",
        "TEMP" => "temperature",
        "_ADJUSTED" => "_adjusted",
        "_ERROR" => "_error",
        "_FLAG_W" => "_flag",
        "_FLAG" => "_flag",
        "_QC" => "_qc",
        "c0mS/cm" => "conductivty",
        "c1mS/cm" => "conductivity",
        "pr" => "pressure",
        "sal00" => "salinity",
        "timeS" => "time_seconds",
        "t090" => "temperature",
        "t090" => "temperature",
        "t090C" => "temperature",
        "t190C" => "temperature",
        "tv290C" => "temperature"
    )
    # Optionally, handle replicates
    if number_replicates && (rval isa Vector)
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
    rval
end
