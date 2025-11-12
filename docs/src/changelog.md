# Changelog from version 0.2.1 to version 0.2.2

Release notes:

### Changed
- none
- BREAKING: none

### Added
- [`get_section`](@ref) for downloading oceanographic 'section' data.


# Changelog from version 0.2.0 to version 0.2.1

Release notes:

### Changed
- none
- BREAKING: none

### Added
- [`read_ctd_rsk`](@ref) added, to read RBR 'Ruskin' files.
- [`set_teos`](@ref) added, to add TEOS-10 hydrographic quantities to an object containing hydrographic data.
- [`station_map`](@ref) added, to illustrate sampling locations relative to nearby coastlines.


# Changelog from version 0.1.0 to version 0.2.0

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



# Changelog from version 0.0.4 to version 0.1.0

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
- add `get_amsr_file()`, `read_amsr()` and `plot_amsr()`
- add `get_topography_file()`, `read_topography()` and `plot_topography()`
- add `N2()`
- add `get_argo_index()`, `get_argo_file()` and `read_argo()`
