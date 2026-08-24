# Changes

Release notes:

## Changelog from version 0.2.14 to version 0.2.15

### Changed

- none

- BREAKING none

### Added

 


## Changelog from version 0.2.13 to version 0.2.14

Release notes:

### Changed

- `get_amsr()` and `plot_amsr()` now handle all 4 data types (`daily`, `3day`, `weekly` and `monthly`)

- BREAKING none

### Added

 



## Changelog from version 0.2.11 to version 0.2.12

Release notes:

### Changed

- `get_file()` gains a new argument named `file`.

- `interpolate_barnes()` finds default `xr` and `yr` based not the number of
  values, but rather the number of distinct values. Also, the return value now
  holds `xr`, `yr`, `gamma` and `iterations`, so that a user can start with the
  default and then make adjustments.

- BREAKING improve freezing-curve drawing syntax. In `plot_TS()`, rename
  `draw_freezing` argument as `plot_freezing`. Rename `draw_freezing_curve!()`
  as `plot_freezing_curve!()`, and remove its `xlim` and `ylim` arguments.

### Added

- `OceanAnalysis.get_tide_gauge_file`
- `OceanAnalysis.get_tide_gauge_index`
- `OceanAnalysis.get_tide_gauge_metadata`



## Changelog from version 0.2.10 to version 0.2.11

Release notes:

### Changed

- `plot_ts()` can handle `color_by=""`.
- `plot_profile()` can handle `color_by=""`.

- BREAKING none yet

### Added

-



## Changelog from version 0.2.9 to version 0.2.10

Release notes:

### Changed

- `as_ctd()` accepts vector values of `longitude` and `latitude`.

- `plot_TS()` can colorize points, given new `color_by` argument.

- `plot_profile()` can colorize points, given new `color_by` argument.

- BREAKING none yet

### Added

- `decode_color_by()`.



## Changelog from version 0.2.7 to version 0.2.8

Release notes:

### Changed

- `plot_amsr` improvements, with new `draw_contours` argument.

- BREAKING none yet

### Added

- Add `add_freezing_curve!`.
- Add `get_erddap_index`.


## Changelog from version 0.2.6 to version 0.2.7

Release notes:

### Changed

- none yet

- BREAKING none yet

### Added

- `plot_TS_isopycnals` and `plot_TS_spiciness`, to add density and spiciness
contours to an existing TS plot. These are now used by `plot_TS`, but it can be
convenient for users to add contours for themselves.
- `ILD_KRH`, to calculate surface isothermal layer depth (ILD) using the Kara
et al. (2000) method.
- `MLD_KRH`, to calculate surface mixed layer depth (MLD) using the Kara
et al. (2000) method.

