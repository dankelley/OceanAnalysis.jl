# History of changes

## 0.1.0

This version is in use by the author, and may also be suitable for other users
who are comfortable with the possibility of changes to function names and
arguments.

### Breaking changes

* Switch to snake-case for function names and argument names. For example, the
  name of `plotTS()` was changed to `plot_TS()`, and its argument
`drawFreezing` was changed to `draw_freezing`.  The point of this is to fit
what seems to be the Julia convention, which has the benefit of reinforcing to
the user that this is distinct from the oce R package, which uses the
camel-case notation.

### Non-breaking changes

* Add support for AMSR data.
* Add support for coastline data.
* Add support for topography data.
* Add `pretty()`, for use in contouring (especially for `plot_TS()`).
* Add `depth_from_pressure()`, `z_from_pressure()`, `pressure_from_depth()`,
  and `pressure_from_z()`.
* Change the second digit of version string to indicate that the package is becoming
  suitable for at least exploratory testing on real data.

## 0.0.3

### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

### Non-breaking changes

* Add built-in data file `ctd.cnv.nc`, and use it in an example in the `Ctd()` documentation.
* Add built-in data file `D4902911_095.nc`, and use it in an example in the `plot_profile()` documentation.
* `get_element()` can now return `"N2"`.
* `plot_profile()` can now plot `N2"`.

## 0.0.2

### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

### Non-breaking changes

* Add `N2()` to compute the square of the buoyancy frequency.

