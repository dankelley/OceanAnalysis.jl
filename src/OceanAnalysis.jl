""" The OceanAnalysis module is intended to help with the analysis of
oceanographic data. It is in a preliminary form, providing help with only four
file types: (1) Argo NetCDF files, (2) CTD files in the Seabird CNV format, (3)
AMSR satellite NetCDF files and (4) coastline files.  In each case, the
capabilities are quite limited, reflecting the early stage of the package.
Users who need more powerful tools for reading and analysing oceanographic
data, ought consider using the `oce` package in the R language, which has more
capabilities and has been in wide use for over a decade.

The functions that read data return objects that are structs holding two items.
The first is a Dict named `metadata`, which has contents that vary with data
type. The second is named `data`, the contents of which depend on the data
type. The elements of both may be accessed directly using the dot notation,
with for example `ctd.data.salinity` refering to the salinity column of ctd
data read by [`read_ctd_cnv`](@ref).  It is also possible to retrieve (or set)
that value using `ctd["salinity"]`.  The advantage of this notation is that it
can locate information whether it is in the `data` or the `metadata` component
of the object. It is also possible to obtain derived information, e.g.
`ctd["SA"]` calculates and then returns the Absolute Salinity, which is not
typically stored in CTD files, but which can be computed from the stored
information. Other derivable items include `"CT"` (Conservative Temperature),
`"sigma0"` (potential density anomaly with respect to surface pressure), and
`spiciness0` (spiciness).
"""
module OceanAnalysis

include("setup.jl")
include("argo.jl")
include("amsr.jl")
include("ctd.jl")
include("ctd_cnv.jl")
include("coastline.jl")
include("download.jl")
include("geod.jl")
include("netcdf.jl")
include("plot.jl")
include("seawater_properties.jl")
include("utilities.jl")

end # module OceanAnalysis
