"""

The OceanAnalysis module is intended to help with the analysis of oceanographic
data. It is in a preliminary form, providing help with only two file types:
Argo NetCDF files and CTD files in the Seabird CNV format.  In neither case
does it read all the data.  If you need more powerful tools for reading and
analysing oceanographic data, consider using the `oce` package in the R
language, which has been in wide use for over a decade old supports many data
types.

The functions that read data return objects that inherit from a base object
named `OA` that is a struct that holds a Dict named `metadata` and a DataFrame
named `data`.  Elements of each may be accessed directly using the dot
notation, with for example `ctd.data.salinity` refering to the salinity column
of ctd data read by [`read_ctd_cnv`](@ref).  It is also possible to retrieve
(or set) that value using `ctd["salinity"]`.  The advantage of this notation is
that it can locate information whether it is in the `data` or the `metadata`
component of the object. It is also possible to obtain *derived* information,
e.g. `ctd["SA"]` calculates and then returns the Absolute Salinity, which is
not typically stored in CTD files, but which can be computed from the stored
information. Other derivable items are `"CT"` (Conservative Temperature),
`"sigma0"` (potential density anomaly with respect to surface pressure),
and `spiciness0` (spiciness).

"""
module OceanAnalysis

using NCDatasets
using Dates
using DataFrames
using GibbsSeaWater
using Plots
using CSV
using Dierckx
using Statistics

# Structs
export OA
export Ctd
#. export Argo

# Functions
export as_ctd
export coordinate_from_string
export CT
export depth_from_pressure
export fix_gsw_bad_code
export fix_gsw_bad_code!
export get_element
export N2
export plot_profile
export plot_TS
export pressure_from_depth
export pressure_from_z
export pretty
export read_argo
export read_ctd_cnv
export salinity_from_conductivity
export SA
export T90_from_T48
export T90_from_T68
export z_from_pressure

"""
    Base object in the [`OceanAnalysis`](@ref) package.
"""
abstract type OA end

"""
    An object to hold CTD data

Ctd is an object to store data from CTD instruments. As a class that derives
from the base object of the package, it is a struct that holds a Dict named
`metadata` and a DataFrame named `data`.  See [`OA`](@ref) for general notes on
the data structure and its access.
"""
struct Ctd <: OA
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

include("argo.jl")
include("ctd.jl")
include("plot.jl")
include("seawater_properties.jl")
include("utilities.jl")

end # module OceanAnalysis
