library(oce)

f <- "/Users/kelley/data/argo/argo_summer_project/D4902122_089.nc"
a <- read.argo(f)
plotTS(a)

f <- "/Users/kelley/data/argo/argo_summer_project/D4902122_089.nc"
a <- read.argo(f)
salinity <- a[["salinity"]]
temperature <- a[["temperature"]]
pressure <- a[["pressure"]]
tail(salinity[,1])
tail(temperature[,1])
tail(pressure[,1])
stopifnot(all.equal(540, sum(is.finite(pressure))))
stopifnot(all.equal(601, sum(is.finite(salinity))))
sum(is.finite(salinity[,1]))
sum(is.finite(temperature[,1]))
sum(is.finite(pressure[,1]))

plotTS(a, eos="unesco", debug=2) # no valid salinity data

ctd <- as.ctd(a, profile=1)
plotTS(ctd)

#<jl<> #last(a["temperature"], 6) # agrees with R
#<jl<> #plot(a["temperature"])
#<jl<> 
#<jl<> ctd = as_ctd(a);
#<jl<> if last(ctd["temperature"], 6) != last(a["temperature"], 6)
#<jl<>     stop("incorrect conversion from argo to ctd")
#<jl<> end
#<jl<> 
#<jl<> # FAILS plot_TS(ctd)
#<jl<> 
#<jl<> S = ctd.data.salinity;
#<jl<> T = ctd.data.temperature;
#<jl<> p = ctd.data.pressure;
#<jl<> lon = ctd.metadata["longitude"];
#<jl<> lat = ctd.metadata["latitude"];
#<jl<> #>SA = gsw_sa_from_sp.(S, p, lon, lat) |> fix_gsw_bad_code!
#<jl<> #SA = gsw_sa_from_sp.(S, p, lon, lat)
#<jl<> #CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
#<jl<> 
#<jl<> plot_TS(ctd)
#<jl<> 
