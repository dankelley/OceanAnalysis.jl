using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000")
beam = read_adp_rdi(file);
xyz = beam_to_xyz(beam);
enu = xyz_to_enu(xyz, declination=-18.1); # decl for local region

# 1. Heatmap of u, v and w
plot_adp(enu; size=(800, 700), dpi=150)
savefig("adp_rdi_heatmap.png")

# 2. U-V scattergraph, with local coastline direction shown

# In R, find angle of coastline for Île-aux-Lièvres
#   load("/Users/kelley/git/oar_book/data/coastlineSLE.rda")
#   plot(coastlineSLE,clon=-69.7,clat=47.79,span=100)
#   ial <- locator(2) # click on ends of IAL
#   xy <- lonlat2utm(lon=ial$x,lat=ial$y)
#   a <- diff(xy$northing)/diff(xy$easting)
plot_adp(enu, which=:uv)
a = 1.71 # from the R code shown above (private file)
plot!([-1; 1], [-a; a], color=:red, label=false, dpi=150)
savefig("adp_rdi_uv.png")


