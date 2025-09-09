using NCDatasets
using Dates
using DataFrames
using Downloads
using GibbsSeaWater
using Plots
using CSV
using Dierckx
using Statistics

# Structs
export OA
export Ctd

# Functions
export argo_id_cycle
export as_ctd
export coordinate_from_string
export CT
export depth_from_pressure
export download_argo_index
export download_argo_file
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
export read_argo_index
export read_ctd_cnv
export salinity_from_conductivity
export SA
export T90_from_T48
export T90_from_T68
export z_from_pressure

"""
    Base type in the OceanAnalysis package.

This is an abstract type. The other types in the package will derive from this.
At the moment, the only such case is [`Ctd`](@ref).
"""
abstract type OA end

"""
    An object to hold CTD data

Ctd is a type used to store data from CTD instruments and Argo floats. It takes
the form of a Struct that derives from the base `OA` type, and holds two items:
(1) a DataFrame named `data` that holds the actual data, including `pressure`,
`salinity`, and `temperature`, perhaps along with other data and (2) a
a Dict named `metadata` that stores information about the data, such as the
`time` of observation and the `latitude` and `longitude` at which
the observation was made.

Objects of type `Ctd` are returned by [`as_ctd`](@ref), [`read_ctd_cnv`](@ref)
and [`read_argo`](@ref) and can be passed to plotting functions [`plot_profile`](@ref)
and [`plot_TS`](@ref), and by several functions relating to seawater properties,
such as [`SA`](@ref) and other TEOS-10 related functions, as well as functions
relating to the distributions of such properties, such as [`N2`](@ref).

"""
struct Ctd <: OA
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end
