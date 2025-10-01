# History of changes

## 0.1.0

This version is in use by the author, and may also be suitable for other users
who are comfortable with the possibility of changes to function names and
arguments.

### Breaking changes

* Switch to the Julia convention of using snake-case for function and argument names. For example, `plotTS()` was renamed [`plot_TS`](@ref), and its argument `drawFreezing` was renamed `draw_freezing`.

### Non-breaking changes

* Add [`subset_amsr`](@ref).
* Add [`toc`](@ref) to provide a table of contents for an [`OA`](@ref) object.
* Add support for coastline data with type [`Coastline`](@ref) plus functions [`coastline`](@ref), [`plot_coastline`](@ref) and [`plot_coastline!`](@ref).
* Add support for topography data with type [`Topography`](@ref) plus functions [`get_topography_file`](@ref)  and [`read_topography`](@ref).
* Add [`pretty`](@ref), for use in contouring (especially for [`plot_TS`](@ref)).
* Add [`depth_from_pressure`](@ref), [`z_from_pressure`](@ref), [`pressure_from_depth`](@ref),
  and [`pressure_from_z`](@ref).
* Change the second digit of version string to indicate that the package is becoming
  suitable for at least exploratory testing on real data.

## 0.0.3

### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

### Non-breaking changes

* Add [`plot_amsr`](@ref).
* Add built-in data file `ctd.cnv.nc`, and use it in an example in the [`Ctd`](@ref) documentation.
* Add built-in data file `D4902911_095.nc`, and use it in an example in the [`plot_profile`](@ref) documentation.
* [`get_element`](@ref) can now return `"N2"`.
* [`plot_profile`](@ref) can now plot `"N2"`.

## 0.0.2

### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

### Non-breaking changes

* Add [`N2`](@ref) to compute the square of the buoyancy frequency.
