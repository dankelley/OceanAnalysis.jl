using OceanAnalysis, Plots, GibbsSeaWater

# R gives
#<R> f <- "/Users/kelley/data/argo/argo_summer_project/D4902122_089.nc"
#<R> a <- read.argo(f)
#<R> temperature <- a[["temperature"]]
#<R> tail(temperature[,1])

# [1] 4.083 4.083 4.083 4.084 4.084 4.084
f = "/Users/kelley/data/argo/argo_summer_project/D4902122_089.nc";
a = read_argo(f);
ctd = as_ctd(a);
if last(ctd["temperature"], 6) != last(a["temperature"], 6)
    stop("incorrect conversion from argo to ctd")
end

plot_TS(ctd)
title!(ctd["filename"])
savefig("01_argo_jl.png")

#last(a["temperature"], 6) # agrees with R
#plot(a["temperature"])

#>lon = ctd.metadata["longitude"];
#>lat = ctd.metadata["latitude"];
#>SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
#SA = gsw_sa_from_sp.(S, p, lon, lat)
#CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
#
#plot_TS(ctd)
#


