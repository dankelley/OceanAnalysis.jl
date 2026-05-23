# Data types provided by OceanAnalysis

[`OA`](@ref) is the foundational base for all the `OceanAnalysis` data types.
In each of those derived types, there are two elements: (1) `metadata`, which
is a Dict holding information about the data (e.g. a sampling location, for a
[`Ctd`] object), and (2) `data`, which may be DataFrame, a Matrix, or some
other data-containing type.

The following outlines the available types and the principle functions relating
to them. See the [online
documentation](https://dankelley.github.io/OceanAnalysis.jl/dev/examples) for
graphical examples of many of these types.

- [`Adp`](@ref) holds data from Acoustic-Doppler Profile data, as read by [`read_adp_rdi`](@ref) and plotted with [`plot_adp`](@ref).

- [`Amsr`](@ref) holds data from AMSR satellites.  The `metadata` item is a
  Dict that holds information about the data source and sampling time. The
  `data` item is a matrix holding the requested field. See [`read_amsr`](@ref)
  for reading such files and plotting their contents.

- [`Argo`](@ref) holds data from Argo profiling floats, as read by [`read_argo`](@ref).

- [`Ctd`](@ref) holds hydrographic data, either from plain CTD instruments or
  from Argo profilers.  In each case, the `metadata` item holds information
  about the data (such as the position and time of sampling), and the `data`
  item is a DataFrame with columns named `salinity`, `temperature` and
  `pressure`, along (in some cases with other columns in the data file). The
  following functions return [`Ctd`](@ref) values: [`as_ctd`](@ref),
  [`read_ctd_cnv`](@ref), [`read_ctd_exchange`](@ref), [`read_ctd_rsk`](@ref)
  and [`read_argo`](@ref).  Objects of type [`Ctd`](@ref) may be plotted with
  [`plot_profile`](@ref) and [`plot_TS`](@ref).

- [`Coastline`](@ref) holds coastline shapes. The `metadata` item is a Dict
  that holds the name of the file from which the data were read (or an
  indication that the data were user-supplied directly). The `data` item is a
  DataFrame with columns named `longitude` and `latitude`. Note that the former
  is in the 0-360 degree range for the built-in datasets. See the documentation
  for [`coastline`](@ref) for reading and plotting such data.

- [`Dem`](@ref) holds digital elevation model datasets, as read with [`read_dem`](@ref).

- [`Echosounder`](@ref) holds data from scientific echosounders, as read with [`read_echosounder`](@ref).

- [`Glider`](@ref) holds data from glider platforms, as read with [`read_glider`](@ref).

- [`Nonna`](@ref) holds high-resolution bathymetry data, as read with [`read_nonna`](@ref).

- [`Section`](@ref) holds a collection of [`Ctd`](@ref) objects constructed
  from hydrographic profiles. Sections may be built up from such profiles with
  [`as_section`](@ref) or [`read_section`](@ref). Archived sections may be
  downloaded with [`get_section`](@ref).  Plots of station locations can be
  created with [`plot_stations`](@ref). Cross-section diagrams of the
  hydrographic data stored in sections (after they are gridded with
  [`grid_section`](@ref)) may be created with [`plot_section`](@ref).

- [`Topography`](@ref) holds topographic information. The `metadata` item is a
  Dict holding items named `"longitude"` and `"latitude"`.  The `data` item is
  a matrix of earth height above mean sea level, in metres. Topographic files
  in NetCDF format may be accessed or downloaded with [`get_topography`](@ref),
  and read with [`read_topography`](@ref). Plots of [`Topography`](@ref)
  objects may created with [`plot_topography`](@ref).
