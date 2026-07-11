"""
    label_from_varname(String::varname, abbreviate::Symbol=:long)

Return a string suitable for use as an axis label.

# Parameters

- `varname` String holding the variable name.
- `abbreviate` Symbol indicating the available size, with valid choices being `:short`, `:medium` and `:large`.

# Examples
```julia
using OceanAnalysis
label_from_varname("CT", :short)
label_from_varname("CT", :medium)
label_from_varname("CT", :large)
label_from_varname("CT") # defaults to :large
```
"""
function label_from_varname(varname::String, abbreviate::Symbol=:long)
    short = Dict(
        "CT" => "CT [°C]",
        "p" => "p",
        "N2" => "N² [s⁻²]",
        "S" => "S",
        "SA" => "SA [g/kg]",
        "salinity" => "Sal.",
        "sigma0" => "σ₀ [kg/m³]",
        "sound_speed" => "Sound Spd. [m/s]",
        "spiciness0" => "π [kg/m³]",
        "temperature" => "T [°C]",
        "theta" => "θ [°C]",
        "T" => "T [°C]"
    )
    medium = Dict(
        "CT" => "Cons. Temp. [°C]",
        "p" => "Pressure",
        "N2" => "Squared Buoy. Freq. [s⁻²]",
        "S" => "Pract. Sal.",
        "SA" => "Abs. Sal. [g/kg]",
        "salinity" => "Salinity",
        "sigma0" => "Pot. Dens. Anom. [kg/m³]",
        "sound_speed" => "Sound Speed [m/s]",
        "spiciness0" => "Spiciness [kg/m³]",
        "temperature" => "Temp. [°C]",
        "theta" => "Pot. Temp. [°C]",
        "T" => "Temperature [°C]"
    )
    long = Dict(
        "CT" => "Conservative Temperature [°C]",
        "p" => "Pressure [dbar]",
        "N2" => "Squared Buoyancy Frequency [s⁻²]",
        "S" => "Practical Salinity",
        "SA" => "Absolute Salinity [g/kg]",
        "salinity" => "Salinity",
        "sigma0" => "Potential Density Anomaly [kg/m³]",
        "sound_speed" => "Sound Speed [m/s]",
        "spiciness0" => "Spiciness [kg/m³]",
        "temperature" => "Temperature [°C]",
        "theta" => "Potential Temperature [°C]",
        "T" => "Temperature [°C]"
    )
    if abbreviate == :short
        varname in keys(short) ? short[varname] : varname
    elseif abbreviate == :medium
        varname in keys(medium) ? medium[varname] : varname
    else
        varname in keys(long) ? long[varname] : varname
    end
end
export label_from_varname

