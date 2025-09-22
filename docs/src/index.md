# OceanAnalysis.jl

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at a very early stage of development by someone
who is new to Julia.  Problems are likely, and changes are a surety.

Click the three-horizontal-line icon at the top left and then click on 'API' to
get an in-depth description of the functions and types in the package.

## Installation

### Official version

Once (if) the package is accepted by the Julia archive system, you may install
it by typing the following in a Julia console.

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

### Development version

#### Somewhat stable (for early users)

Type the following in a Julia console to use the "main" branch from the
development website. This is updated after significant changes to the "develop"
branch (that have passed the built-in test suite).

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
```

#### Unstable (for developers)

Type the following in a Julia console to use the "develop" branch from the
development website.  Be aware that this branch may hold features that are
poorly documented, that are not destined for inclusion in the "main" branch,
and that may simply fail.

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl", rev="develop")
```

#### Breaking changes

* Switch to snake-case for function names and argument names. For example, the
  name of `plotTS()` was changed to `plot_TS()`, and its argument
`drawFreezing` was changed to `draw_freezing`.  The point of this is to fit
what seems to be the Julia convention, which has the benefit of reinforcing to
the user that this is distinct from the oce R package, which uses the
camel-case notation.

#### Non-breaking changes

* Add support for coastline files.
* Add support for AMSR datasets.
* Add `pretty()`, for use in contouring (especially for `plot_TS()`).
* Add `depth_from_pressure()`, `z_from_pressure()`, `pressure_from_depth()`,
  and `pressure_from_z()`.
* Change the second digit of version string to indicate that the package is becoming
  suitable enough for exploratory testing on real data.

### 0.0.3

#### Breaking changes

There are no breaking changes; all changes are additions or bug fixes.

#### Non-breaking changes

* Add built-in data file `ctd.cnv.nc`, and use it in an example in the `Ctd()` documentation.
* Add built-in data file `D4902911_095.nc`, and use it in an example in the `plot_profile()` documentation.
* `get_element()` can now return `"N2"`.
* `plot_profile()` can now plot `N2"`.

### 0.0.2

#### Breaking changes

There are no breaking changes; all changes are additions or bug fixes.

#### Non-breaking changes

* Add `N2()` to compute the square of the buoyancy frequency.

# Developer notes

## Running tests

There is a small test suite built into the package.  To run it, type the
following in a Julia console:

```julia
]
activate .
test OceanAnalysis
```

## Building the documentation

To build, type the following in a shell terminal. (Change the `/Users/kelley`
part, as appropriate.)

```sh
cd /Users/kelley/git/OceanAnalysis.jl
julia --project=. docs/make.jl
```

To view, do the following in a Julia console.  (Change the `/Users/kelley` part, as
appropriate.)

```julia
cd("/Users/kelley/git/OceanAnalysis.jl/")
using LiveServer
serve(; dir="docs/build", launch_browser=true)
```
