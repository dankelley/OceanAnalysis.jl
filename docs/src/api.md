# API Reference

Some functions in the package serve a general purpose, while others are keyed to data types.

## General-purpose functions

There are many such functions. For example, [`get_file`](@ref) is a cached
download function that will download a remote file and install it locally,
skipping the download if there is already a local version that was downloaded
sufficiently recently.  Within the package, this is used for Argo files, but
users are free to use it for any other file type.  Similarly, [`pretty`](@ref)
provides a way to get simple increments to be used in contouring, but users may
find it helpful for a variety of other purposes. In addition to these, there
are many functions that deal with water properties, distances between points on
the earth, etc.  The names are designed to be reasonably straightforward, and
so scanning the full API list will be a good guide for users.

## Special-purpose functions

The package offers several special-purpose functions that are tied to data
types.  The following listing provides a rough guideline, keyed to the data
type.  The examples should also be helpful in getting acquainted with the
functions, and the data types.

## Type inheritance

- [`OA`](@ref) is the base type in the package. All of the following types
  inherit from [`OA`](@ref).

- [`Ctd`](@ref) holds hydrographic data, from plain CTD instruments or Argo
  files.  See [`as_ctd`](@ref), [`read_ctd_cnv`](@ref), and [`read_argo`](@ref)
  for constructing data objects of type [`Ctd](@ref). See
    [`plot_profile`](@ref) and [`plot_TS`](@ref) for plotting them. .

- [`Amsr`](@ref) holds data from AMSR satellites.  See [`read_amsr`](@ref) for
  reading such files and plotting their contents.

- [`Coastline`](@ref) holds coastline shapes.  See [`coastline`](@ref) for
  reading and plotting such data.

## Links to detailed type documentation

```@docs
OceanAnalysis.OA
OceanAnalysis.Amsr
OceanAnalysis.Ctd
OceanAnalysis.Coastline
```

## Links to detailed function documentation

```@docs
OceanAnalysis.argo_id_cycle
OceanAnalysis.as_ctd
OceanAnalysis.coastline
OceanAnalysis.coordinate_from_string
OceanAnalysis.CT
OceanAnalysis.depth_from_pressure
OceanAnalysis.fix_gsw_bad_code
OceanAnalysis.fix_gsw_bad_code!
OceanAnalysis.geod_distance
OceanAnalysis.get_argo_index
OceanAnalysis.get_argo_file
OceanAnalysis.get_element
OceanAnalysis.get_file
OceanAnalysis.get_nc_value
OceanAnalysis.N2
OceanAnalysis.OceanAnalysis
OceanAnalysis.plot_coastline
OceanAnalysis.plot_coastline!
OceanAnalysis.plot_profile
OceanAnalysis.plot_TS
OceanAnalysis.pressure_from_depth
OceanAnalysis.pressure_from_z
OceanAnalysis.pretty
OceanAnalysis.read_amsr
OceanAnalysis.read_argo
OceanAnalysis.read_argo_index
OceanAnalysis.read_ctd_cnv
OceanAnalysis.SA
OceanAnalysis.T90_from_T48
OceanAnalysis.T90_from_T68
OceanAnalysis.z_from_pressure
```
