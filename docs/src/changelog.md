# Changelog from version 0.1.0 to version 0.1.1

Release notes:

### Changed
- [`as_ctd`](@ref) accepts ranges as well as vectors for `salinity`, `temperature` and `pressure`.
- [`coastline`](@ref) accepts ranges for `longitude` and `latitude`, in addition to vectors.
- [`coastline`](@ref) throws an error on CSV files that lack columns named "longitude" and "latitude".
- Argo trajectory map added to Examples.
- BREAKING: none

### Added
- [`scale_bar`](@ref) to add a scale bar to a map plot



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
