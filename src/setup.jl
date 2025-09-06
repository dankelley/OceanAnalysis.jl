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
export argo_id_cycle
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
    Base object in the OceanAnalysis package.
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
