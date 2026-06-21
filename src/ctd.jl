"""
    as_ctd(a::Argo; add_teos::Bool=false, debug::Integer=0)

Convert an Argo object into a Ctd object.

# Return value

This returns a `Ctd` object, with `metadata` and `data` copied from `a`, and possibly with new `data` columns holding computed values of some key TEOS-10 values.

# Arguments

- `a` an [`Argo`](@ref) object.

# Keywords

- `add_teos` a logical value indicating whether to add TEOS-10 items (e.g. `SA`) to the `data` portion of the return value.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

"""
function as_ctd(a::Argo; add_teos::Bool=false, debug::Integer=0)
    oad(debug, "as_ctd(Argo, ...)")
    oad(debug, "  add_teos: $(add_teos)")
    rval = Ctd(deepcopy(a.metadata), deepcopy(a.data))
    if add_teos
        ncol0 = ncol(rval.data)
        rval = set_teos(rval, debug=increment_debug(debug))
        ncol1 = ncol(rval.data)
        oad(debug, "  inserted TEOS-10 values into data, increasing column count from $ncol0 to $ncol1")
    end
    oad(debug, "END as_ctd(Argo, ...)")
    rval
end

"""
    as_ctd(salinity::Union{AbstractVector,AbstractRange},
        temperature::Union{AbstractVector,AbstractRange},
        pressure::Union{AbstractVector,AbstractRange};
        longitude::Real=-63.0, latitude::Real=45.0, time=nothing,
        add_teos::Bool=true, debug::Integer=0)::Ctd

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

- `longitude`: observation longitude, in degrees East. The default, -63.0, is a location in the North Atlantic).

- `latitude`: observation latitude, in degrees North. The default, 45.0, is a location in the North Atlantic).

- `time`: an optional indication of the measurement start time.

- `add_teos`: an optional indication of whether to add `SA`, `CT`, `sigma0` and `spiciness0` to the `data` component of the return value.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples
```julia
using OceanAnalysis
julia> using OceanAnalysis

julia> as_ctd([32.], [15.], [0.], add_teos=false)
Ctd(Dict{String, Any}("filename" => nothing, "latitude" => [45.0], "time" => nothing, "longitude" => [-63.0]), 1×3 DataFrame
 Row │ salinity  temperature  pressure
     │ Float64   Float64      Float64
─────┼─────────────────────────────────
   1 │     32.0         15.0       0.0)

julia> as_ctd([32.], [15.], [0.], longitude=40.0, latitude=-63.0)
Ctd(Dict{String, Any}("filename" => nothing, "latitude" => [-63.0], "time" => nothing, "longitude" => [40.0]), 1×7 DataFrame
 Row │ salinity  temperature  pressure  SA       CT       sigma0   spiciness0
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────
   1 │     32.0         15.0       0.0  32.1539  15.0641  23.6671   0.0704222)

```
"""
function as_ctd(salinity::Union{AbstractVector,AbstractRange},
    temperature::Union{AbstractVector,AbstractRange},
    pressure::Union{AbstractVector,AbstractRange};
    longitude::Real=-63.0, latitude::Real=45.0, time=nothing,
    add_teos::Bool=true, debug::Integer=0)::Ctd
    oad(debug, "as_ctd(salinity, ...) START")
    nsamp = length(salinity)
    length(temperature) == nsamp || error("salinity and temperature have differing lengths ($nsamp and $(length(temperature)), respectively)")
    length(pressure) == nsamp || error("salinity and pressure have differing lengths ($nsamp and $(length(pressure)), respectively)")
    oad(debug, "  assembling data as a DataFrame with $nsamp rows")
    data = DataFrame(salinity=salinity, temperature=temperature, pressure=pressure)
    oad(debug, "  assembling metadata (a Dict)")
    metadata = Dict{String,Any}(
        "filename" => nothing,
        "longitude" => longitude,
        "latitude" => latitude,
        "time" => time)
    oad(debug, "  passing metadata and data to Ctd()")
    rval = Ctd(metadata, data)
    if add_teos
        oad(debug, "  inserting TEOS-10 values into data")
        rval = set_teos(rval, debug=increment_debug(debug))
    end
    oad(debug, "END as_ctd(salinity, ...)")
    rval
end # as_ctd()


"""
    set_teos(x::OA; debug::Integer=0)::Ctd

Add, or modify, TEOS-10 components to hydrographic data.

Compute the TEOS-10 quantities `SA` (Absolute Salinity), `CT` (Conservative
Temperature), `sigma0` (potential density anomaly with respect to surface pressure),
and `spiciness0` (seawater spiciness with respect to surface pressure).
These items are inserted into the `data` component of the returned value. If
they are already present in `x`, then new values are inserted in the
return value.

An error is reported if the `x.data` lacks `salinity`, `temperature` or
`pressure`, or if `x.metadata` lacks `longitude` or `latitude`.

Any `longitude` values that are NaN are converted to -30.0, while
any `latitude` values that are NaN are converted to 30.0. These
values corresponde to the mid-Atlantic.
"""
function set_teos(x::OA; debug::Integer=0)::Ctd
    oad(debug, "set_teos START")
    metadata = copy(x.metadata)
    data = copy(x.data)
    metadata_names = keys(metadata)
    oad(debug, "  metadata_names: ", metadata_names)
    data_names = names(data)
    oad(debug, "  data_names: ", data_names)
    required_cols = ("salinity", "temperature", "pressure")
    data_names = string.(names(data))
    missing_cols = filter(c -> !(c in data_names), required_cols)
    isempty(missing_cols) || error("lacking required data columns: $(missing_cols)")
    required_metadata = ("longitude", "latitude")
    missing_metadata = filter(k -> !(k in keys(metadata)), required_metadata)
    isempty(missing_metadata) || error("lacking required metadata: $(missing_metadata)")
    oad(debug, "  have requisite hydrographic and location data, so can set TEOS-10 variables")
    S = data.salinity
    T = data.temperature
    p = data.pressure
    lon = metadata["longitude"]
    lat = metadata["latitude"]
    if !isa(lon, AbstractVector)
        lon = fill(lon, length(S))
    elseif length(lon) != length(S)
        error("length(longitude) ($(length(lon))) must equal number of samples ($(length(S)))")
    end
    if !(isa(lat, AbstractVector))
        lat = fill(lat, length(S))
    elseif length(lat) != length(S)
        error("length(latitude) ($(length(lat))) must equal number of samples ($(length(S)))")
    end
    bad_lon = isnan.(lon)
    if any(bad_lon)
        @warn "NaN longitudes converted to -30E"
        lon[bad_lon] = -30.0
    end
    bad_lat = isnan.(lat)
    if any(bad_lat)
        @warn "NaN latitudes converted to 30N"
        lat[bad_lat] = 30.0
    end
    !any(isnan.(lon)) || error("cannot handle NaNs in longitude")
    !any(isnan.(lat)) || error("cannot handle NaNs in latitude")
    data.SA = similar(S)
    data.SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
    data.CT = similar(T)
    data.CT = gsw_ct_from_t.(data.SA, T, p) |> fix_gsw_bad_code!
    data.sigma0 = gsw_sigma0.(data.SA, data.CT) |> fix_gsw_bad_code!
    data.spiciness0 = gsw_spiciness0.(data.SA, data.CT) |> fix_gsw_bad_code!
    rval = Ctd(metadata, data)
    oad(debug, "END set_teos")
    rval
end

"""
    grid_ctd(ctd::Ctd;
        pressure_grid::Union{AbstractVector,AbstractRange,Nothing}=nothing, pressure_step::Real=2.0,
        method::Symbol=:interpolate, debug::Integer=0)::Ctd

Grid a CTD to standardized pressure levels.

The levels are as given by `pressure_grid` or, if that is not provided,
as a sequence that starts at 0 dbar and increments by `pressure_step` until
the value exceeds the maximum pressure in `ctd`.

# Arguments

- `ctd` a [`Ctd`](@ref) to be gridded. It must contain a `pressure` column.

# Keywords

- `method`: a symbol indicating the gridding method; this must be `:interpolate`, indicating linear interpolation to the specified pressure grid.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Example

```julia
using OceanAnalysis, Plots
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
ctd = read_ctd_cnv(f);
# Using double the data resolution, given mean Δp 0.237 and median 0.238
ctd2 = grid_ctd(ctd, pressure_step=0.1);
plot_profile(ctd, which="salinity")
plot!(ctd2["salinity"], ctd2["pressure"], color=:red)
```
"""
function grid_ctd(ctd::Ctd;
    pressure_grid::Union{AbstractVector,AbstractRange,Nothing}=nothing, pressure_step::Real=2.0,
    method::Symbol=:interpolate, debug::Integer=0)::Ctd
    oad(debug, "grid_ctd() START")
    method == :interpolate || throw(ArgumentError("method=:$method not handled; try :interpolate"))
    pressure_step > 0.0 || throw(ArgumentError("pressure_step must be > 0.0"))
    if isnothing(pressure_grid)
        pressure_grid = 0.0:pressure_step:maximum(ctd.data.pressure)
        oad(debug, "  set pressure_grid to ", first(pressure_grid, 3), "...", last(pressure_grid, 2))
    end
    "pressure" in names(ctd.data) || error("no pressure in Ctd object")
    pressure_orig = ctd.data.pressure
    valid = .!ismissing.(pressure_orig) .& .!isnan.(pressure_orig)
    any(valid) || error("no valid pressure data")
    num_bad = count(.!valid)
    if num_bad > 0
        oad(debug, "  removed $num_bad rows with missing/NaN pressure values")
    end
    pressure = pressure_orig[valid]
    order = sortperm(pressure)
    pressure_sorted = pressure[order]
    Interpolations.deduplicate_knots!(pressure_sorted)
    nrow = length(pressure_grid)
    ncol = size(ctd.data)[2]
    arr = Array{Float64}(undef, nrow, ncol)
    column_names = string.(names(ctd.data))
    for i in 1:ncol
        col = ctd.data[:, i][valid][order]
        # We use the grid for pressure
        if column_names[i] == "pressure"
            arr[:, i] = collect(pressure_grid)
            continue
        end
        # Cannot interpolate non-numeric quantitles (like QC codes)
        if !(eltype(col) <: Number)
            arr[:, i] = fill(NaN, nrow)
            continue
        end
        # this interpolation is good for ML at top and low variation at bottom
        itp = linear_interpolation((pressure_sorted,), col, extrapolation_bc=Flat())
        arr[:, i] = itp.(pressure_grid)
    end
    data = DataFrame(arr, names(ctd.data))
    rval = Ctd(deepcopy(ctd.metadata), data)
    oad(debug, "END grid_ctd()")
    rval
end

