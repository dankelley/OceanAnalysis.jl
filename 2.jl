using OceanAnalysis
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
x = coastline();
x.metadata["longitude"] = 3
x.metadata["latitude"] = 3
x.data.salinity .= 1
x.data.temperature .= 1
x.data.pressure .= 1
ctd = as_ctd(x, debug=1)
