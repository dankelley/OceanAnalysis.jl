using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000")
adp = read_adp_rdi(file);
adp_xyz = beam_to_xyz(adp);
plot_adp(adp_xyz; size=(800, 700), dpi=150)
#savefig("adp_rdi.png")
