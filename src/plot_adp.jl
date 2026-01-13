"""
    plot_adp(adp::Adp; debug=0)

Plot the data stored in an [`Adp`](@ref) object.

This is a very limited and provisional function. At the moment, `which`
is ignored, and only velocity may be plotted. The plot stacks panels
vertically, one for each beam.

# Arguments

- `adp` an Adp, as created with [`read_adp_rdi`](@ref).

# Keywords

- `debug`: an optional integer value that, if it exceeds 0, indicates that debugging output should be printed during processing.

- `kwargs`: optional items, passed down to the `heatmap` function used to plot images.

# Examples
```juliadoc
using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000")
adp_beam = read_adp_rdi(file);
plot_adp(adp_beam)
adp_xyz = beam_to_xyz(adp_beam);
plot_adp(adp_xyz)
```
"""
function plot_adp(adp::Adp; which=:velocity, debug::Int64=0, kwargs...)
    oad(debug, "plot_adp() START")
    if adp["coordinate_system"] == :beam
        titles = ["beam 1", "beam 2", "beam 3", "beam 4"]
    elseif adp["coordinate_system"] == :xyz
        titles = ["u", "v", "w", "error"]
    elseif adp["coordinate_system"] == :enu
        error("FIXME: the :enu coordinate_system is not handled yet")
    end
    x = adp["time"]
    y = adp["distance"]
    v = adp["velocity"]
    c = cgrad(:RdBu, rev=true)
    z = transpose(v[:, :, 1])
    # Centre colourbar on 0
    clim = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)]))
    p1 = heatmap(x, y, z,
        title=titles[1], titlelocation=:right,
        guidefontsize=8, tickfontsize=8, titlefontsize=8,
        size=(800, 600), ylab="Distance [m]",
        framestyle=:box, c=c, clim=clim; kwargs...)
    z = transpose(v[:, :, 2])
    clim = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)]))
    p2 = heatmap(x, y, z,
        title=titles[2], titlelocation=:right,
        guidefontsize=8, tickfontsize=8, titlefontsize=8,
        size=(800, 600), ylab="Distance [m]",
        framestyle=:box, c=c, clim=clim; kwargs...)
    z = transpose(v[:, :, 3])
    clim = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)]))
    p3 = heatmap(x, y, z,
        title=titles[3], titlelocation=:right,
        guidefontsize=8, tickfontsize=8, titlefontsize=8,
        size=(800, 600), ylab="Distance [m]",
        framestyle=:box, c=c, clim=clim; kwargs...)
    z = transpose(v[:, :, 4])
    clim = (-1.0, 1.0) .* maximum(abs.(z[.!isnan.(z)]))
    p4 = heatmap(x, y, z,
        title=titles[4], titlelocation=:right,
        guidefontsize=8, tickfontsize=8, titlefontsize=8,
        size=(800, 600), ylab="Distance [m]",
        framestyle=:box, c=c, clim=clim; kwargs...)
    rval = plot(p1, p2, p3, p4, layout=@layout[a; b; c; d])
    oad(debug, "END plot_adp()")
    rval
end
