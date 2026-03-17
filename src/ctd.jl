"""
    as_ctd(a::Argo; add_teos::Bool=false, debug::Int64=0)

Convert an Argo object into a Ctd object.

# Return Value

This returns a `Ctd` object, with `metadata` and `data` copied from `a`, and possibly with new `data` columns holding computed values of some key TEOS-10 values.

# Arguments

- `a` an [Argo] object.

# Keywords

- `add_teos` a logical value indicating whether to add TEOS-10 items (e.g. `SA`) to the `data` portion of the return value.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

"""
function as_ctd(a::Argo; add_teos::Bool=false, debug::Int64=0)
    rval = Ctd(a.metadata, a.data)
    if add_teos
        oad(debug, "  inserting TEOS-10 values into data")
        rval = set_teos(rval, debug=increment_debug(debug))
    end
    oad(debug, "END as_ctd()")
    rval
end

"""
    as_ctd(salinity::Union{AbstractVector,AbstractRange},
        temperature::Union{AbstractVector,AbstractRange},
        pressure::Union{AbstractVector,AbstractRange};
        longitude::Real=-63.0, latitude::Real=45.0, time=nothing,
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
Ctd(Dict{String, Any}("filename" => nothing, "latitude" => 40.0, "time" => nothing, "longitude" => -63.0), 1×7 DataFrame
 Row │ salinity  temperature  pressure  SA       CT       sigma0   spiciness0
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────
   1 │     32.0         15.0       0.0  32.1516  15.0642  23.6653   0.0686905)
```
"""
function as_ctd(salinity::Union{AbstractVector,AbstractRange},
    temperature::Union{AbstractVector,AbstractRange},
    pressure::Union{AbstractVector,AbstractRange};
    longitude::Real=-63.0, latitude::Real=45.0, time=nothing,
    add_teos::Bool=true, debug::Int64=0)
    oad(debug, "as_ctd(<ctd>, debug=$debug) START")
    #oad(debug, "  given salinity (length: $(length(salinity)), max: $(maximum(filter(!isnan, salinity))))")
    oad(debug, "  given salinity of length ", length(salinity), ", which starts: ", first(salinity, 2))
    oad(debug, "  given temperature of length ", length(temperature), ", which starts: ", first(temperature, 2))
    oad(debug, "  given pressure of length ", length(pressure), ", which starts: ", first(pressure, 2))
    oad(debug, "  given longitude:  ", longitude)
    oad(debug, "  given latitude:   ", latitude)
    oad(debug, "  assembling data (a DataFrame)")
    data = DataFrame(salinity=salinity, temperature=temperature, pressure=pressure)
    oad(debug, "  assembling metadata (a Dict)")
    metadata = Dict{String,Any}()
    metadata["filename"] = nothing
    metadata["longitude"] = longitude
    metadata["latitude"] = latitude
    if !ismissing(time)
        metadata["time"] = time
    end
    oad(debug, "  passing metadata and data to Ctd()")
    rval = Ctd(metadata, data)
    if add_teos
        oad(debug, "  inserting TEOS-10 values into data")
        rval = set_teos(rval, debug=increment_debug(debug))
    end
    oad(debug, "END as_ctd()")
    rval
end # as_ctd()


"""
    set_teos(x::OA; debug::Int64=0)

Add, or modify, TEOS-10 components to hydrographic data.

Compute the TEOS-10 quantities `SA` (Absolute Salinity), `CT` (Conservative
Temperature), `sigma0` (potential density anomaly with respect to surface pressure),
and `spiciness0` (seawater spiciness with respect to surface pressure).
These items are inserted into the `data` component of the returned value. If
they are already present in `x`, then new values are inserted in the
return value.

An error is reported if the `x.data` lacks `salinity`, `temperature` or
`pressure`, or if `x.metadata` lacks `longitude` or `latitude`.
"""
function set_teos(x::OA; debug::Int64=0)
    oad(debug, "set_teos10 START")
    metadata = copy(x.metadata)
    data = copy(x.data)
    metadata_names = keys(metadata)
    oad(debug, "  metadata_names: ", metadata_names)
    data_names = names(data)
    oad(debug, "  data_names: ", data_names)
    data_needed = ("salinity", "temperature", "pressure")
    has_needed_data = [x in data_names for x in data_needed]
    sum(has_needed_data) == 3 || error("lacking 'salinity', 'temperature' or 'pressure' in data ")
    metadata_needed = ("longitude", "latitude")
    has_needed_metadata = [x in metadata_names for x in metadata_needed]
    sum(has_needed_metadata) == 2 || error("lacking 'longitude' or 'latitude' in metadata ")
    oad(debug, "  have requisite hydrographic and location data, so can set TEOS-10 variables")
    S, T, p = data.salinity, data.temperature, data.pressure
    lon, lat = metadata["longitude"], metadata["latitude"]
    data.SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    oad(debug, "  SA completed, starting with ", first(data.SA, 2))
    data.CT = gsw_ct_from_t.(data.SA, T, p) |> fix_gsw_bad_code!
    oad(debug, "  CT completed, stating with : ", first(data.CT, 2))
    data.sigma0 = gsw_sigma0.(data.SA, data.CT) |> fix_gsw_bad_code!
    oad(debug, "  sigma0 completed, starting with ", first(data.sigma0, 2))
    data.spiciness0 = gsw_spiciness0.(data.SA, data.CT) |> fix_gsw_bad_code!
    oad(debug, "  spiciness0 completed, starting with ", first(data.spiciness0, 2))
    rval = Ctd(metadata, data)
    oad(debug, "END set_teos")
    rval
end

"""
    grid_ctd(ctd::Ctd;
        pressure_grid::Vector{Float64}=missing, pressure_step::Float64=2.0;
        method::Symbol=:interpolate, debug::Int64=0)

Grid a CTD to standardized pressure levels.

The levels are as given by `pressure_grid` or, if that is not provided,
as the pressure range within `ctd`, incrementing by `pressure_step`.

# Arguments

- `ctd` a [`Ctd`](@ref) to be gridded. It must contain a `pressure` column.

# Keywords

- `method`: a symbol indicating the gridding method. At the moment, only one choice is accepted, namely `:interpolate`, which means to use linear interpolation of each field to the specified pressure grid.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Example

```juliadoc
using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
ctd = read_ctd_cnv(f);
pressure_grid = 0.0:1.0:100.0;
ctd2 = grid_ctd(ctd, pressure_grid=pressure_grid);
plot(ctd["salinity"], -ctd["pressure"], seriestype=:path, legend=false, framestyle=:box)
plot!(ctd2["salinity"], -ctd2["pressure"], seriestype=:path, color=:red, legend=false, framestyle=:box)
```
"""
function grid_ctd(ctd::Ctd;
    pressure_grid::Union{AbstractVector,AbstractRange}=missing, pressure_step::Float64=2.0,
    method::Symbol=:interpolate, debug::Int64=0)
    oad(debug, "grid_ctd() START")
    method == :interpolate || error("only method=:interpolate is handled in this version")
    if ismissing(pressure_grid)
        pressure_grid = range(0, extremum(ctd.data.pressure)[2], step=pressure_step)
        oad(debug, "  set pressure_grid to ", first(pressure_grid, 3), "...", last(pressure_grid, 2))
    end
    pressure = ctd.data.pressure
    Interpolations.deduplicate_knots!(pressure)
    nrow = length(pressure_grid)
    ncol = size(ctd.data)[2]
    rval = zeros(nrow, ncol)
    column_names = names(ctd.data)
    for i in 1:ncol
        if column_names[i] == "pressure"
            rval[:, i] = pressure_grid
        else
            itp = linear_interpolation((pressure,), ctd.data[:, i], extrapolation_bc=NaN)
            rval[:, i] = itp.(pressure_grid)
        end
    end
    data = DataFrame(rval, :auto)
    rename!(data, names(ctd.data))
    rval = Ctd(ctd.metadata, data)
    oad(debug, "END grid_ctd()")
    rval
end

