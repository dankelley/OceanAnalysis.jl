using OceanAnalysis, Plots
get_info_for_oce = false
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
d = read_adp_rdi(file);
v = d["velocity"]
tm = d["transformation_matrix"]
ne = size(v)[1]
V = Array{Float64}(undef, size(v));
for i in 1:ne
    V[i, :, :] = v[i, :, :] * transpose(tm)
end
CM = cgrad(:RdBu, rev=true)
p1 = heatmap(transpose(v[:, :, 1]), c=CM, title="beam 1", titlefontsize=9);
p2 = heatmap(transpose(V[:, :, 2]), c=CM, title="beam 2", titlefontsize=9);
p3 = heatmap(transpose(v[:, :, 3]), c=CM, title="beam 3", titlefontsize=9);
p4 = heatmap(transpose(v[:, :, 4]), c=CM, title="beam 4", titlefontsize=9);
pu = heatmap(transpose(V[:, :, 1]), c=CM, title="u", titlefontsize=9);
pv = heatmap(transpose(v[:, :, 2]), c=CM, title="v", titlefontsize=9);
pw = heatmap(transpose(V[:, :, 3]), c=CM, title="w", titlefontsize=9);
pe = heatmap(transpose(V[:, :, 4]), c=CM, title="err", titlefontsize=9);
plot(p1, p2, p3, p4, layout=(4, 1))
savefig("01_beam_jl.png")
plot(pu, pv, pw, pe, layout=(4, 1))
savefig("01_xyz_jl.png")

if get_info_for_oce # get numbers so can subset in R/oce
    f = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
    # next takes 1.3s on first use, 0.6s on second call
    @time d = read_adp_rdi(f)
    t_start = DateTime("2008-06-26")
    t_end = DateTime("2008-06-27")
    t = d["time"]
    keep = t_start .<= t .<= t_end
    start = findfirst(keep) # 5041
    last = findlast(keep) # 13681
    use = range(start, last, step=360)
    println("start: $start, last: $last, step: 360")
    @time d = read_adp_rdi(f, use)
    d["time"]
end
