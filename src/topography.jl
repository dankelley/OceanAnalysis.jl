"""
    get_topography_file(name::Symbol=:global_coarse; debug::Int64=0)

Access a built-in topography dataset.

The only valid choice for `name` is `:global_coarse`, which returns a world
view at resolution of 30 minutes, i.e. with grid cells near the equator
spanning approximately 30 nautical miles.

See also [`read_topography`](@ref).

"""
function get_topography_file(name::Symbol=:global_coarse; debug::Int64=0)
    oad(debug, "get_topography_file(name) BEGIN")
    dir = dirname(dirname(pathof(OceanAnalysis)))
    if name == :global_coarse
        rval = joinpath(dir, "data", "topo_180W_180E_90S_90N_30min_netcdf.nc")
    else
        error("    expecting 'name' to be :global_coarse, but :", name, " was provided")
    end
    oad(debug, "END get_topography_file()")
    rval
end

"""
    read_topography(filename::String; debug::Int64 = 0)

Read a topography file that is in NetCDF format. The return value stores
longitude in `rval.metadata["longitude"]`, latitude in
`rval.metadata["latitude"]`, and depth in `rval.data`. Note that the depth
matrix is transposed, to make it easier to plot.

See also [`get_topography_file`](@ref).

# Examples

```juliadoc
# Plot world view of ocean depth
using OceanAnalysis, Plots
topo_file = get_topography_file(:global_coarse);
topo = read_topography(topo_file);
water_depth = -topo.data / 1000.0; # depth (i.e. negative height) in km
water_depth[water_depth .< 0.0] .= NaN; # trim land
heatmap(topo.metadata["longitude"], topo.metadata["latitude"], water_depth,
    asp=1.0, framestyle=:box, xlims=[-180,180], ylims=[-90,90],
    color=cgrad(:deep, rev=false), dpi=300)
cl = coastline();
plot!(cl.data.longitude, cl.data.latitude, color=:black, legend=false, linewidth=0.5)
```
"""
function read_topography(filename::String; debug::Int64=0)
    filename = expanduser(filename)
    oad(debug, "read_topography(\"", filename, "\", ...) BEGIN")
    NCDataset(filename, "r") do nc
        oad(debug, "    about to read topography data.")
        metadata = Dict()
        metadata["filename"] = filename
        # FIXME: do we need to copy in a case like this?
        metadata["longitude"] = copy(nc["lon"])
        metadata["latitude"] = copy(nc["lat"])
        # Transpose because of the file setup.
        data = copy(Float64.(replace(nc["Band1"], missing => NaN)))'
        oad(debug, "    matrix dimension: ", size(data))
        oad(debug, "END read_topography()")
        return Topography(metadata, data)
    end
end
