using DataFrames

"""
    Base type in the OceanAnalysis package.

This is an abstract type, from which other types in the library
are derived.
"""
abstract type OA end


"""
    A type to hold acoustic-Doppler profiler data

Adp is a type used to store data from an ADP (acoustic-Doppler profiler).
It holds two items: `data` (a Dict that holds data in array form) and
`metadata` (a Dict with information about the data).

Adp objects may be created with [`read_adp_rdi`](@ref), which only handles RDI data.  (Use the `oce` R package if you need other instrument types.) See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#Acoustic-Doppler-Profiler-Data) for an illustration.

"""
mutable struct Adp <: OA
    metadata::Dict{String,Any}
    data::Dict{String,Any}
end

"""
    A type to hold AMSR satellite data

This holds AMSR satellite data as read by [`read_amsr`](@ref).

The `metadata` element is a Dict that holds the source `filename`, the
`sensor`, the `name` of the stored variable, the observation interval
(`"time_coverage_start"` and `time_coverage_end`) and the vectors (`longitude`
and `latitude`) that define the grid.

The `data` element is a matrix holding the gridded data.
"""
mutable struct Amsr <: OA
    metadata::Dict{String,Any}
    data::Matrix{Float64}
end


"""
    A type to hold Argo data

Argo is a type used to store data from Argo floats.

Argo objects hold two components: a DataFrame named `data` that holds the
actual data, and a Dict named `metadata` that stores information about the
data, e.g. the sampling time, the location, etc. Objects of type `Argo` are
returned by [`read_argo`](@ref), which reads the NetCDF files in which
Argo data are distributed.

For many purposes, it may be useful to convert Argo objects
into Ctd objects, using [`as_ctd`](@ref). See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#Argo-Data) for an illustration.
"""
mutable struct Argo <: OA
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

"""
    A type to hold CTD data

Ctd is a type used to store data from CTD instruments. It holds
two items: (1) a DataFrame named `data` that holds the actual data, including
`pressure`, `salinity`, and `temperature`, perhaps along with other data and
(2) a Dict named `metadata` that stores information about the data, such as
the `time` of observation and the `latitude` and `longitude` at which the
observation was made.

Objects of type `Ctd` are returned by [`as_ctd`](@ref), [`read_ctd_cnv`](@ref),
[`read_ctd_rsk`](@ref) and [`read_argo`](@ref).  Such objects can be passed to
plotting functions [`plot_profile`](@ref) and [`plot_TS`](@ref), and to some
functions relating to seawater properties, such as [`SA`](@ref) and other
TEOS-10 related functions, as well as functions relating to the distributions
of such properties, such as [`N2`](@ref).

See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#CTD-Data) for an illustration.
"""
mutable struct Ctd <: OA
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

See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#Coastle-Data) for an illustration.

"""
mutable struct Coastline <: OA
    metadata::Dict{String,Any}
    data::DataFrames.DataFrame
end

"""
    A type to hold echosounder data

Echosounder is a type to hold data from a Biosonics scientific echosounder, as
read with [`read_echosounder`](@ref). Its `metadata` and `data` are both Dict
objects. See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#Echosounder-Data) for an illustration.
"""
mutable struct Echosounder <: OA
    metadata::Dict{String,Any}
    data::Dict{String,Any}
end

"""
    A type to hold NONNA bathymetry data

This holds bathymetric data as read by [`read_nonna`](@ref). See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#High-resolution-bathymetry-data) for an illustration.

The `metadata` element is a Dict that holds the source `filename` along with vectors named `longitude` and `latitude` that define the grid.

The `data` element stores a matrix of bathymetry data in terms of height above mean sea level, in metres.
"""
mutable struct Nonna <: OA
    metadata::Dict{String,Any}
    data::Matrix{Float64}
end


"""
    Section is a type that holds section data

The `data` portion of a Section object is a Vector of [`Ctd`](@ref)
objects, while the `metadata` portion may contain information about the
collection. See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#Section-Data) for an illustration.

Section objects may be assembled from CTD objects using [`as_section`](@ref) or
read from CTD files with [`read_section`](@ref). They may be gridded with
[`grid_section`](@ref) and plotted with [`plot_section`](@ref).

"""
mutable struct Section <: OA
    metadata::Dict{String,Any}
    data::Vector{Ctd}
end



"""
    A type to hold topography data

This holds topography data as read by [`read_topography`](@ref).
See the [online documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples/#Low-resolution-bathymetry-data) for an illustration.

The `metadata` element is a Dict that holds the source `filename` along with
vectors holding the `longitude` and `latitude` values that define the grid.

The `data` element stores a matrix of topography data in terms of height
above mean sea level, in metres.
"""
mutable struct Topography <: OA
    metadata::Dict{String,Any}
    data::Matrix{Float64}
end

