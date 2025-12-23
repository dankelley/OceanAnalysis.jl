# Data types provided by OceanAnalysis

[`OA`](@ref) is the foundational base for all the `OceanAnalysis` data types. In each
of those derived types, there are two elements: (1) a Dict named `metadata` and (2)
a DataFrame, Matrix, or some other data-containing object named `data`.

The following outlines the available types and the principle functions relating
to them.

- [`Amsr`](@ref) holds data from AMSR satellites.  The `metadata` item is a
  Dict that holds information about the data source and sampling time. The
  `data` item is a matrix holding the requested field. See [`read_amsr`](@ref)
  for reading such files and plotting their contents.

- [`Ctd`](@ref) holds hydrographic data, either from plain CTD instruments or
  from Argo profilers.  In each case, the `metadata` item holds information
  about the data (such as the position and time of sampling), and the `data`
  item is a DataFrame with columns named `salinity`, `temperature` and
  `pressure`, along (in some cases with other columns in the data file). The
  following functions return [`Ctd`](@ref) values: [`as_ctd`](@ref),
  [`read_ctd_cnv`](@ref), and [`read_argo`](@ref).  Objects of type
  [`Ctd`](@ref) may be plotted with [`plot_profile`](@ref) and
  [`plot_TS`](@ref).

- [`Coastline`](@ref) holds coastline shapes. The `metadata` item is a Dict
  that holds the name of the file from which the data were read (or an
  indication that the data were user-supplied directly). The `data` item is a
  DataFrame with columns named `longitude` and `latitude`. Note that the former
  is in the 0-360 degree range for the built-in datasets. See the documentation
  for [`coastline`](@ref) for reading and plotting such data.

- [`Section`](@ref) holds a collection of CTD (or similar) stations in an
  oceanographic "section". See [`as_section`](@ref) for how Section objects are
  typically constructed.

- [`Topography`](@ref) holds topographic information. The `metadata` item is a
  Dict holding items named `"longitude"` and `"latitude"`.  The `data` item is
  a matrix of earth height above mean sea level, in metres. Topographic
  files in NetCDF format may be accessed or downloaded with [`get_topography_file`](@ref),
  and read with [`read_topography`](@ref).
