"""

The OceanAnalysis module is intended to help with the analysis of oceanographic
data. It is in a preliminary form, providing help with the following data
types: ADP (RDI) files, AMSR satellite NetCDF files, Argo NetCDF files, CTD
files in the Seabird CNV format, and coastline files.
In each case, the capabilities are quite limited, reflecting the early stage of the package.
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
either the `metadata` or `data` parts of an OceanAnalysis object. It may also
be used to calculate some information that can be inferred from what is
actually stored in the object, e.g. Conservative Temperature and Absolute
Salinity.

Plotting was done with the `Plots` system in the earliest days of this
package, but a switch to `Makie` was made in the autumn of 2026.  The reason
was that `Plots` imposes limitations on work that the author commonly wants
to do, e.g. putting depth contours on SST satellite image. For a gentle
introduction to Makie, see Ref 1. More context, in a journal
format, is provided in Ref 2. Full details of the system are
provided in Ref 3.

# References

1. https://docs.makie.org/stable/ - A blog item introducting Makie
   https://medium.com/coffee-in-a-klein-bottle/visualizing-data-with-julia-using-makie-7685d7850f06

2. Danisch, Simon, and Julius Krumbiegel. “Makie.Jl: Flexible High-Performance
   Data Visualization for Julia.” Journal of Open Source Software 6, no. 65
   (2021): 3349. https://doi.org/10.21105/joss.03349.

3. MakieOrg. “Makie Interactive Data Visualizations and Plotting in Julia.”
   2026. https://docs.makie.org/stable/.

"""
module OceanAnalysis

# Constants
include("constants.jl")

# Type definitions
include("types.jl")

# Functions
include("setup.jl")
include("adp_rdi.jl")
include("argo.jl")
include("amsr.jl")
include("bin.jl")
include("ctd.jl")
include("ctd_cnv.jl")
include("ctd_exchange.jl")
include("ctd_rsk.jl")
include("coastline.jl")
include("dem.jl")
include("despike.jl")
include("echosounder.jl")
include("erddap.jl")
include("geod.jl")
include("get.jl")
include("glider.jl")
include("interpolate_barnes.jl")
include("label.jl")
include("magnetic_field.jl")
include("mld_cf.jl")
include("mld_krh.jl")
include("N2.jl")
include("nonna.jl")
include("netcdf.jl")
include("plot_adp.jl")
include("plot_amsr.jl")
include("plot_coastline.jl")
include("plot_echosounder.jl")
include("plot_profile.jl")
include("plot_section.jl")
include("plot_stations.jl")
include("plot_TS.jl")
include("qc.jl")
include("rename_data.jl")
include("running.jl")
include("seawater_properties.jl")
include("section.jl")
include("subset.jl")
include("summarize.jl")
include("tide_gauge.jl")
include("topography.jl")
include("utilities.jl")


#<disabled> import PrecompileTools
#<disabled> PrecompileTools.@compile_workload begin
#<disabled>     # precompile some argo and ctd functions that may be common
#<disabled>     pkgdir = dirname(dirname(pathof(OceanAnalysis)))
#<disabled>     argo_file = joinpath(pkgdir, "data", "D4902911_095.nc")
#<disabled>     argo = read_argo(argo_file)
#<disabled>     ctd = as_ctd(argo)
#<disabled>     plot_profile(ctd)
#<disabled>     plot_TS(ctd)
#<disabled>     e = get_element(ctd, "temperature")
#<disabled> end

end # module OceanAnalysis
