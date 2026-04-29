# Changes

## Changelog from version 0.2.2 to version 0.2.3

### Changed

- none yet

- BREAKING none yet

### Added

- [`bin_mean`](@ref).
- [`drop_qc`](@ref).
- [`N2_first_difference`](@ref).
- [`N2_spline`](@ref).
- [`Glider`](@ref) data type, with [`read_glider`](@ref) to read such data.

## Changelog from version 0.2.1 to version 0.2.2

Release notes:

### Changed

- none

- BREAKING: [`read_argo`](@ref) returns an Argo object, so a call to [`as_ctd`](@ref) is required before using e.g. [`plot_TS`](@ref).

### Added

- [`as_ctd`](@ref) can convert Argo objects to Ctd objects
- [`as_section`](@ref) for assembling 'ctd' data into a section.
- [`beam_to_xyz`](@ref) for converting RDI acoustic-Doppler data from beam coordinates to xyz coordinates.
- [`despike`](@ref) for removing anomalous values in time series data.
- [`get_section`](@ref) for downloading oceanographic section data.
- [`grid_ctd`](@ref) for gridding Ctd data.
- [`grid_section`](@ref) for gridding Section data.
- [`interpolate_barnes`](@ref) for gridding with Barnes' method.
- [`label_from_varname`](@ref) for creating axis labels.
- [`plot_adp`](@ref) for plotting acoustic-Doppler profiler data.
- [`plot_echosounder`](@ref) for plotting Biosonics echosounder data.
- [`plot_section`](@ref) for plotting oceanographic 'section' data.
- [`plot_stations`](@ref) for plotting sampling locations.
- [`read_adp_rdi`](@ref) for reading RDI acoustic-Doppler profiler data.
- [`read_ctd_exchange`](@ref) for reading CTD data in 'exchange' format (used by many data servers)
- [`read_echosounder`](@ref) for reading Biosonics echosounder data.
- [`read_section`](@ref) for reading Section data.
- [`rename_data`](@ref) for converting data names to standardized names.
- [`running_mean`](@ref) added.
- [`running_median`](@ref) added.
- [`subset_ctd`](@ref) for subsetting Ctd objects.
- `summarize` for summarizing OA objects.
- [`xyz_to_enu`](@ref) for converting RDI acoustic-Doppler data from xyz coordinates to enu coordinates.

## Changelog from version 0.2.0 to version 0.2.1

Release notes:

### Changed

- none
- BREAKING: none

### Added

- [`read_ctd_rsk`](@ref) added, to read RBR 'Ruskin' files.
- [`set_teos`](@ref) added, to add TEOS-10 hydrographic quantities to an object containing hydrographic data.
- [`station_map`](@ref) added, to illustrate sampling locations relative to nearby coastlines.

## Changelog from version 0.1.0 to version 0.2.0

Release notes:

### Changed

- [`as_ctd`](@ref) accepts ranges as well as vectors for `salinity`, `temperature` and `pressure`.
- [`coastline`](@ref) accepts ranges for `longitude` and `latitude`, in addition to vectors.
- [`coastline`](@ref) on a CSV file throws an error if columns named "longitude" and "latitude" are not found.
- BREAKING: none

### Added

- The Examples tab of the online documentation shows hot to create an Argo-trajectory map.
- [`coriolis`](@ref) computes the Coriolis parameter.
- [`gravity`](@ref) computes the acceleration due to earth gravity.
- [`scale_bar`](@ref) adds a scale bar to a map plot.

## Changelog from version 0.0.4 to version 0.1.0

Release notes:

### Changed

- improve consistency of `;` placement in functions
- improve code documentation, e.g. fixing erroneous line breaks in list items
- BREAKING: rename `getElement()` as `get_element()`.
- BREAKING: rename `plotProfile()` as `plot_profile()`.
- BREAKING: rename `plotTS()` as `plot_TS()`.
- BREAKING: rename `readArgo()` as `read_argo()`.
- BREAKING: rename `readCtdCnv()` as `read_ctd_cnv()`.

### Added

- add `coastline()`, `plot_coastline()` and `plot_coastline!()`
- add `get_amsr()`, `read_amsr()` and `plot_amsr()`
- add `get_topography()`, `read_topography()` and `plot_topography()`
- add `N2()`
- add `get_argo_index()`, `get_argo()` and `read_argo()`
