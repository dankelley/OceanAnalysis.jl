using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
function oad(debug, msg)
    debug < 1 || println(msg)
end
adp = read_adp_rdi(file);
"""
    beamToXyz(adp::Adp; debug=0)

    Change velocity in an RDI Adp object from beam to xyz coordinates

This is done by using the `transformation_matrix` that is stored within `adp`.  See
[`read_adp_rdi`](@ref) for how to read an RDI [`Adp`](@ref) object.
"""
function beamToXyz(adp::Adp; debug=0)
    oad(debug, "beamToXyz() BEGIN")
    adp["coordinate_system"] == :beam || error("adp[\"coordinate_system\"] is not :beam")
    tmt = transpose(adp["transformation_matrix"])
    vbeam = adp.data["velocity"]
    dim = size(vbeam)
    vxyz = Array{Float64}(undef, dim)
    ne = dim[1]
    for i in 1:ne
        vxyz[i, :, :] = vbeam[i, :, :] * tmt
    end
    data = copy(adp.data)
    data["velocity"] = vxyz
    metadata = copy(adp.metadata)
    metadata["coordinate_system"] = :xyz
    rval = Adp(metadata, data)
    oad(debug, "END beamToXyz()")
    rval
end
adp_xyz = beamToXyz(adp);
v = adp.data["velocity"];
V = adp_xyz.data["velocity"];
CM = cgrad(:RdBu, rev=true);
p1 = heatmap(transpose(v[:, :, 1]), c=CM, title="beam 1", titlefontsize=9);
p2 = heatmap(transpose(v[:, :, 2]), c=CM, title="beam 2", titlefontsize=9);
p3 = heatmap(transpose(v[:, :, 3]), c=CM, title="beam 3", titlefontsize=9);
p4 = heatmap(transpose(v[:, :, 4]), c=CM, title="beam 4", titlefontsize=9);
pu = heatmap(transpose(V[:, :, 1]), c=CM, title="u", titlefontsize=9);
pv = heatmap(transpose(V[:, :, 2]), c=CM, title="v", titlefontsize=9);
pw = heatmap(transpose(V[:, :, 3]), c=CM, title="w", titlefontsize=9);
pe = heatmap(transpose(V[:, :, 4]), c=CM, title="err", titlefontsize=9);
plot(p1, p2, p3, p4, layout=(4, 1), size=(1000, 700))
savefig("02_beam_jl.png")
plot(pu, pv, pw, pe, layout=(4, 1), size=(1000, 700))
savefig("02_xyz_jl.png")
