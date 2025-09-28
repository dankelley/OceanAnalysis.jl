"""
    as_ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64};
        longitude::Float64=-63.0, latitude::Float64=45.0, time=nothing,
        add_teos::Bool=true, debug::Int64=0)

Construct a [`Ctd`](@ref) object, given S, T, p, and possibly a location.

Returns a [`Ctd`](@ref) object with a `data` element that is a data frame
holding the provided water properties, along with computed Absolute Salinity
(`SA`) Conservative Temperature (`CT`), potential density anomaly relative to
the surface pressure (`sigma0`) and spiciness with respect to surface pressure
(`spiciness0`).  The object also holds a `metadata` element that holds
`longitude`, `latitude` and `time`.  If either `longitude` or `latitude` is
NaN, then`SA`, etc. are computed assuming a mid-Atlantic location (-30E and
30N).

# Arguments

- `salinity`: measured salinity values, in Practical Salinity units.

- `temperature`: measured temperature values, in degrees Celsius.

- `pressure`: measured sea pressure values, in dbar.

# Keywords

- `longitude`: observation longitude, in degrees East. The default is a location in the North Atlantic).

- `latitude`: observation latitude, in degrees North. The default is a location in the North Atlantic).

- `time`: an optional indication of the measurement start time.

- `add_teos`: an optional indication of whether to add `SA`, `CT`, `sigma0` and `spiciness0` to the `data` component of the return value.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples
```jldoctest
julia> using OceanAnalysis

julia> as_ctd([32.], [15.], [0.], add_teos=false)
Ctd(Dict{String, Any}("latitude" => 45.0, "time" => nothing, "longitude" => -63.0), 1×3 DataFrame
 Row │ salinity  temperature  pressure
     │ Float64   Float64      Float64
─────┼─────────────────────────────────
   1 │     32.0         15.0       0.0)


julia> as_ctd([32.], [15.], [0.], longitude=-63., latitude=40.)
Ctd(Dict{String, Any}("latitude" => 40.0, "time" => nothing, "longitude" => -63.0), 1×7 DataFrame
 Row │ salinity  temperature  pressure  SA       CT       sigma0   spiciness0
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────
   1 │     32.0         15.0       0.0  32.1516  15.0642  23.6653   0.0686905)


julia> as_ctd([32.], [15.], [0.], longitude=-63., latitude=30.)
Ctd(Dict{String, Any}("latitude" => 30.0, "time" => nothing, "longitude" => -63.0), 1×7 DataFrame
 Row │ salinity  temperature  pressure  SA       CT       sigma0   spiciness0
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────
   1 │     32.0         15.0       0.0  32.1511  15.0642  23.6649   0.0683062)
```
"""
function as_ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64};
    longitude::Float64=-63.0, latitude::Float64=45.0, time=nothing,
    add_teos::Bool=true, debug::Int64=0)
    oad(debug, "as_ctd(<ctd>, debug=$debug) START")
    #oad(debug, "    given salinity (length: $(length(salinity)), max: $(maximum(filter(!isnan, salinity))))")
    oad(debug, "    given salinity of length ", length(salinity), ", which starts: ", first(salinity, 2))
    oad(debug, "    given temperature of length ", length(temperature), ", which starts: ", first(temperature, 2))
    oad(debug, "    given pressure of length ", length(pressure), ", which starts: ", first(pressure, 2))
    oad(debug, "    given longitude:  ", longitude)
    oad(debug, "    given latitude:   ", latitude)
    oad(debug, "    assembling data (a DataFrame) from the above")
    data = DataFrame(salinity=salinity, temperature=temperature, pressure=pressure)
    if add_teos
        oad(debug, "    adding TEOS-10 variables")
        data.SA = gsw_sa_from_sp.(salinity, pressure, longitude, latitude) |> fix_gsw_bad_code!
        oad(debug, "    created SA, starting with ", first(data.SA, 2))
        data.CT = gsw_ct_from_t.(data.SA, temperature, pressure) |> fix_gsw_bad_code!
        oad(debug, "    created CT, stating with : ", first(data.CT, 2))
        data.sigma0 = gsw_sigma0.(data.SA, data.CT) |> fix_gsw_bad_code!
        oad(debug, "    created sigma0, starting with ", first(data.sigma0, 2))
        data.spiciness0 = gsw_spiciness0.(data.SA, data.CT) |> fix_gsw_bad_code!
        oad(debug, "    created spiciness0, starting with ", first(data.spiciness0, 2))
    end
    oad(debug, "    assembling metadata (a Dict)")
    metadata = Dict{String,Any}()
    # DELETE     Note that we are inserting the longitude and latitude from the function call,
    # DELETE     not the -30,30 values that we invented in order to estimate SA, CT, sigma0 and spicines0
    metadata["longitude"] = longitude
    metadata["latitude"] = latitude
    if !ismissing(time)
        metadata["time"] = time
    end
    oad(debug, "    passing metadata and data to Ctd()")
    rval = Ctd(metadata, data)
    oad(debug, "END as_ctd()")
    rval
end # as_ctd()
