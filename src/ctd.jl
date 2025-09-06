"""
    as_ctd(salinity, temperature, pressure, longitude=NaN, latitude=NaN; time, debug=-1)

Construct a [`Ctd`](@ref) object, given S, T, p, and a location.

Returns a [`Ctd`](@ref) object with a `data` element that is a data frame
holding the provided water properties, along with computed Absolute Salinity
(`SA`) Conservative Temperature (`CT`), potential density anomaly relative to
the surface pressure (`sigma0`) and spiciness with respect to surface pressure
(`spiciness0`).  The object also holds a `metadata` element that holds
`longitude`, `latitude` and `time`.  If either `longitude` or `latitude` is
NaN, then`SA`, etc. are computed assuming a mid-Atlantic location (-30E and
30N).

# Arguments
- `salinity::Vector{Float64}` measured salinity values, in Practical Salinity units.
- `temperature::Vector{Float64}` measured temperature values, in degrees Celsius.
- `pressure::Vector{Float64}` measured sea pressure, in dbar.
- `longitude::Float64` observation longitude, in degrees East. If not provided, this defaults
    to -30 (i.e. -30E, or 30W, in the North Atlantic).
- `latitude::Float64` observation latitude, in degrees North. If not provided, this defaults
    to 30 (i.e. 30N, in the North Atlantic).
- `time::Date.DateTime` an optional indication of the measurement start time.
- `add_teos::Bool` an optional indication of whether to add `SA`, `CT`,
  `sigma0` and `spiciness0` to the `data` component of the return value.
- `debug::Int64` an optional value that, if it exceeds 0, indicates that
    debugging output should be printed during processing.
"""
function as_ctd(salinity::Vector{Float64}, temperature::Vector{Float64}, pressure::Vector{Float64},
    longitude::Float64=NaN, latitude::Float64=NaN; time=nothing,
    add_teos::Bool=false, debug::Int64=0)
    #<> # Examples
    #<> ```julia
    #<> julia> using OceanAnalysis
    #<> julia> as_ctd([32.],[15.],[0.],-63.,40.)
    #<> Ctd(Dict{String, Any}("latitude" => 40.0, "time" => nothing, "longitude" => -63.0), 1×3 DataFrame
    #<>  Row │ salinity  temperature  pressure
    #<>      │ Float64   Float64      Float64
    #<> ─────┼─────────────────────────────────
    #<>    1 │     32.0         15.0       0.0)
    #<> ```
    oad(debug, "as_ctd(<ctd>, debug=$debug) START")
    #oad(debug, "    given salinity (length: $(length(salinity)), max: $(maximum(filter(!isnan, salinity))))")
    oad(debug, "    given salinity of length ", length(salinity), ", which starts: ", first(salinity, 2))
    oad(debug, "    given temperature of length ", length(temperature), ", which starts: ", first(temperature, 2))
    oad(debug, "    given pressure of length ", length(pressure), ", which starts: ", first(pressure, 2))
    oad(debug, "    given longitude:  ", longitude)
    oad(debug, "    given latitude:   ", latitude)
    oad(debug, "    assembling data (a DataFrame) from the above")
    # DELETE   data = DataFrame(salinity=salinity, temperature=temperature,
    # DELETE       pressure=pressure, SA=SA, CT=CT, sigma0=sigma0, spiciness0=spiciness0)
    data = DataFrame(salinity=salinity, temperature=temperature, pressure=pressure)
    if add_teos
        if ismissing(longitude) || ismissing(latitude) || isnan(longitude) || isnan(latitude)
            lon = -30.0
            lat = 30.0
            println("as_ctd() given NaN longitude/latitude values, so SA, CT, etc. computed at -30E, 30N.")
        else
            lon = longitude
            lat = latitude
        end
        data.SA = gsw_sa_from_sp.(salinity, pressure, lon, lat) |> fix_gsw_bad_code!
        oad(debug, "    created SA of length ", length(SA), ", which starts: ", first(SA, 2))
        data.CT = gsw_ct_from_t.(data.SA, temperature, pressure) |> fix_gsw_bad_code!
        oad(debug, "    created CT of length ", length(CT), ", which starts: ", first(CT, 2))
        data.sigma0 = gsw_sigma0.(data.SA, data.CT) |> fix_gsw_bad_code!
        oad(debug, "    created sigma0 of length ", length(sigma0), ", which starts: ", first(sigma0, 2))
        data.spiciness0 = gsw_spiciness0.(data.SA, data.CT) |> fix_gsw_bad_code!
        oad(debug, "    created spiciness0 of length ", length(spiciness0), ", which starts: ", first(spiciness0, 2))
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
    oad(debug, "    passing metadata and data to Ctd() to construct a return value")
    rval = Ctd(metadata, data)
    oad(debug, "END as_ctd()")
    rval
end # as_ctd()
