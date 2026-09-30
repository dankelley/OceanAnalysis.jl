"""
    rename_data(names::Union{String,Vector{String}};
        number_replicates::Bool=true, debug::Integer=0)

Rename data items from labels used in files to names used in code.

# Arguments

- `names` a String holding a name to be converted, or a vector of such strings.

- `number_replicates` a Bool value indicating whether to prevent duplicated
  names by appending numbers to duplicates.  This is true by default. For
  example, the first salinity would be named `salinity`, while the second would
  be named `salinity2`.

# Return value

A String or vector of String items, holding new names.  If any of the converted
names appear more than once, then digits are appended (see last example).

# Examples

```julia
using OceanAnalysis
rename_data("CTDPRS") #"pressure"

rename_data(["CTDPRS", "CTDTMP"]) # 2-element Vector{String}: "pressure" "temperature"

rename_data(["CTDPRS", "CTDTMP", "CTDTMP_FLAG"]) # 3-element Vector{String}: "pressure" "temperature" "temperature_flag"
```
"""
function rename_data(names::Union{String,Vector{String}};
    number_replicates::Bool=true, debug::Integer=0)
    oad(debug, "rename_data() START")
    oad(debug, "    names: $names")
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
        "c0S/m" => "conductivity", # but note the unit
        "c0mS/cm" => "conductivity",
        "c1mS/cm" => "conductivity",
        "dz/dtM" => "dz/dt",
        "flSP" => "fluorescence",
        "prdM" => "pressure", # must put before 'pr'
        "pr" => "pressure",
        "pressuredM" => "pressure",
        "sal00" => "salinity",
        "sbeox0ML/L" => "oxygen",
        "timeS" => "time_seconds",
        "t090" => "temperature",
        "t090" => "temperature",
        "t090C" => "temperature",
        "t190C" => "temperature",
        "tv290C" => "temperature"
    )
    # Optionally, handle replicates
    if number_replicates > 0 && (rval isa Vector)
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
    oad(debug, "    rval: $rval")
    oad(debug, "END rename_data()")
    return rval
end
export rename_data
