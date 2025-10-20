using DataFrames

"""
    Base type in the OceanAnalysis package.

This is an abstract type. The other types in the package will derive from this.
At the moment, the only such case is [`Ctd`](@ref).
"""
abstract type OA end

"""
    A type to hold CTD data

Ctd is a type used to store data from CTD instruments and Argo floats. It takes
the form of a Struct that derives from the base `OA` type, and holds two items:
(1) a DataFrame named `data` that holds the actual data, including `pressure`,
`salinity`, and `temperature`, perhaps along with other data and (2) a
a Dict named `metadata` that stores information about the data, such as the
`time` of observation and the `latitude` and `longitude` at which
the observation was made.

Objects of type `Ctd` are returned by [`as_ctd`](@ref), [`read_ctd_cnv`](@ref),
[`read_ctd_rsk`](@ref) and [`read_argo`](@ref).  Such objects can be passed to
plotting functions [`plot_profile`](@ref) and [`plot_TS`](@ref), and to some
functions relating to seawater properties, such as [`SA`](@ref) and other
TEOS-10 related functions, as well as functions relating to the distributions
of such properties, such as [`N2`](@ref).

"""
struct Ctd <: OA
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

"""
    A type to hold coastline data

Coastline is a type to hold coastline data.  Its `metadata` element is a Dict that
may hold the source filename or other information (or may be empty).  Its
`data` element is a DataFrame holding columns named `longitude` and `latitude`,
with NaN values separating continents and/or elements within them such
as countries or subregions of countries.
"""
struct Coastline <: OA
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

"""
    A type to hold AMSR data (SUBJECT TO CHANGE)

This holds AMSR satellite data as read by [`read_amsr`](@ref).

The `metadata` element is a Dict that holds the source `filename`, the
`sensor`, the `name` of the stored variable, the observation interval
(`"time_coverage_start"` and `time_coverage_end`) and the vectors (`longitude`
and `latitude`) that define the grid.

The `data` element is a matrix holding the gridded data.
"""
struct Amsr <: OA
    metadata::Dict{String,Any}
    data::Matrix{Float64}
end

"""
    A type to hold topography data (SUBJECT TO CHANGE)

This holds topography data as read by [`read_topography`](@ref).

The `metadata` element is a Dict that holds the source `filename` along with
vectors holding the `longitude` and `latitude` values that define the grid.

The `data` element stores a matrix of topography data in terms of height
above mean sea level, in metres.
"""
struct Topography <: OA
    metadata::Dict{String,Any}
    data::Matrix{Float64}
end
