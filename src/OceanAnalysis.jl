"""
The OceanAnalysis module is intended to help with the analysis of oceanographic
data. It is in a preliminary form, providing help with only two file
types: Argo NetCDF files and CTD files in the Seabird CNV format.  In neither
case does it read all the data.  If you need more powerful tools for
reading and analysing oceanographic data, consider using the `oce` package
in the R language, which over a decade old and supports many data types.
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
export Oce
export Ctd
#. export Argo

# Functions
export as_ctd
export coordinate_from_string
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

abstract type Oce end

"""
    An object to hold CTD data

This is a struct that holds a Dict named `metadata` and a DataFrame named `data`.
"""
struct Ctd <: Oce
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

include("argo.jl")
include("ctd.jl")
include("plot.jl")
include("sw.jl")
include("utilities.jl")

end # module OceanAnalysis
