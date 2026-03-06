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
        "S" => "S",
        "SA" => "SA [g/kg]",
        "CT" => "CT [°C]",
        "N2" => "N² [s⁻²]",
        "sigma0" => "σ₀ [kg/m³]",
        "spiciness0" => "π [kg/m³]",
        "theta" => "θ [°C]",
        "T" => "T [°C]"
    )
    medium = Dict(
        "S" => "Pract. Sal.",
        "SA" => "Abs. Sal. [g/kg]",
        "CT" => "Cons. Temp. [°C]",
        "N2" => "Squared Buoy. Freq. [s⁻²]",
        "sigma0" => "Pot. Dens. Anom. [kg/m³]",
        "spiciness0" => "Spiciness [kg/m³]",
        "theta" => "Pot. Temp. [°C]",
        "T" => "Temperature [°C]"
    )
    long = Dict(
        "S" => "Practical Salinity",
        "SA" => "Absolute Salinity [g/kg]",
        "CT" => "Conservative Temperature [°C]",
        "N2" => "Squared Buoyancy Frequency [s⁻²]",
        "sigma0" => "Potential Density Anomaly [kg/m³]",
        "spiciness0" => "Spiciness [kg/m³]",
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

