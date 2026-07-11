"""
    get_nc_value(nc, name; require_valid=false)

Transform an item from a NetCDF file into a more useable object.

Any missing values are converted to NaN.  This function is designed only for
numerical values, not strings or other types.

# Arguments

- `nc` a value returned by `NCDataset()`.

- `name` the name of an object contained in `nc`.

# Keywords

- `require_value` boolean value indicating whether to report an error if the desired element consists entirely of bad values.
"""
function get_nc_value(nc, name; require_valid=false)
    if !(name in keys(nc))
        @warn "this NetCDF file does not contain a data element named $name"
        return NaN
    end
    local item = nc[name]
    # NetCDF format stores even scalars as vectors.
    ndim = ndims(item)
    if ndim == 1
        item = item[1]
    elseif ndim == 2
        item = item[:, 1]
    elseif ndim == 3
        item = item[:, :, 1]
    else
        error("ndim of \"$name\" must be 1, 2 or 3, but it is $ndim")
    end
    bad = ismissing.(item)
    # FIXME: why not return NaN values, to let the calling code deal with this?
    if require_valid && all(bad)
        error("the ", name, " field contains no non-missing values")
    end
    if any(bad)
        #if all(ismissing.(item))
        #    println("returning early -- all data are missing (WTF DAN FIXME)")
        #    return item
        #end
        item[ismissing.(item)] .= NaN
    end
    # FIXME: is this right?
    if ndim == 1
        rval = convert(Float64, item)
    elseif ndim == 2
        rval = convert(Vector{Float64}, item)
    elseif ndim == 3
        rval = convert(Matrix{Float64}, item)
    else
        error("cannot handle ndim=", ndim, " case")
    end
    return rval
end
export get_nc_value
