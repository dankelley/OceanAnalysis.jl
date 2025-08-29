using NCDatasets
d = NCDataset("D4902911_095.nc", "r")
platform = replace(join(d["PLATFORM_NUMBER"][:, 1]), "missing" => "")
println("'$platform'")
