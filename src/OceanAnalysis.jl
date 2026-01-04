""" The OceanAnalysis module is intended to help with the analysis of
oceanographic data. It is in a preliminary form, providing help with only four
file types: (1) Argo NetCDF files, (2) CTD files in the Seabird CNV format, (3)
AMSR satellite NetCDF files and (4) coastline files.  In each case, the
capabilities are quite limited, reflecting the early stage of the package.
Users who need more powerful tools for reading and analysing oceanographic
data, ought consider using the `oce` package in the R language, which has more
capabilities and has been in wide use for over a decade.

The functions that read data return objects that are structs holding two items:
`data` and `metadata`.

* The `data` item holds the actual data. The form of the data depends on the
class of the object.  For example, in a [`Ctd`](@ref) object, `data` is a
`DataFrame`, whereas in a [`Section`](@ref) object, `data` is a Vector of
[`Ctd`](@ref) objects.

* The `metadata` item holds information about the data.  For example, with a
[`Ctd`](@ref) object, `metadata` holds the location and time of sampling, along
with other information, depending on the source of the data.

As a convenience, [`get_element`](@ref) may be used to extract information from
either the `metadata` or `data` parts of an OceanAnalysis object.

FIXME: discuss the fact that [`get_element`](@ref) can return derived
quantities.

FIXME: discuss `[` here.  I think maybe we ought to cause `[` to call
`get_element` regardless of the object class. But, in that case, is there any
need for [`get_element`](@ref) at all?
"""
module OceanAnalysis

include("types.jl")
include("setup.jl")
include("adp_rdi.jl")
include("argo.jl")
include("amsr.jl")
include("ctd.jl")
include("ctd_cnv.jl")
include("ctd_exchange.jl")
include("ctd_rsk.jl")
include("coastline.jl")
include("geod.jl")
include("get.jl")
include("netcdf.jl")
include("plot_profile.jl")
include("plot_section.jl")
include("plot_stations.jl")
include("plot_TS.jl")
include("seawater_properties.jl")
include("section.jl")
include("topography.jl")
include("utilities.jl")

end # module OceanAnalysis
