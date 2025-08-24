# OceanAnalysis.jl

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at a very early stage of development by someone who
is in the early steps of exploring Julia as a supplement to R.

## Installation

### Official version

Once (if) the package is accepted by the Julia archive system, you may install
it by typing the following in a Julia console.

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

### Development version

#### Somewhat stable (for early users)

Type the following in a Julia console.

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
```

#### Unstable (for developers)

Type the following in a Julia console.

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl", rev="develop")
```

## Usage Examples

### CTD file

```julia
# Read a built-in CTD file, and plot some hydrographic diagrams
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "ctd.cnv")
ctd = read_ctd_cnv(filename)
p1 = plot_profile(ctd, "SA")
p2 = plot_profile(ctd, "CT")
p3 = plot_TS(ctd)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
```

![Sample plot of CTD data in a .cnv file](examples/cnv_example.png)

### Argo file

```julia
# Read a built-in Argo file, and plot some hydrographic diagrams
using OceanAnalysis, Plots, Measures
filename = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data",
    "D4902911_095.nc")
ctd = read_argo(filename)
p1 = plot_profile(ctd, "SA")
p2 = plot_profile(ctd, "CT")
p3 = plot_TS(ctd)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin=0.25cm)
```

![Sample plot of Argo data](examples/argo_example.png)

## History of changes

### 0.1.0

This version is in use by the author, and may also be suitable for other users
who are comfortable with the possibility of changes to function names and
arguments.

#### Breaking changes

* Switch to snake-case for function names and argument names. For example, the
  name of `plotTS()` was changed to `plot_TS()`, and its argument
`drawFreezing` was changed to `draw_freezing`.  The point of this is to fit
what seems to be the Julia convention, which has the benefit of reinforcing to
the user that this is distinct from the oce R package, which uses the
camel-case notation.

#### Non-breaking changes

* Increase second version digit to indicate that the package is becoming
  suitable for testing on real data.
* Simplify coding with respect to debugging information.

### 0.0.3

#### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

#### Non-breaking changes

* Add built-in data file `ctd.cnv.nc`, and use it in an example in the `Ctd()` documentation.
* Add built-in data file `D4902911_095.nc`, and use it in an example in the `plot_profile()` documentation.
* `get_element()` can now return `"N2"`.
* `plot_profile()` can now plot `N2"`.

### 0.0.2

#### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

#### Non-breaking changes

* Add `N2()` to compute the square of the buoyancy frequency.

# Developer notes

## Running tests

Type the following in a Julia console:

```julia
activate .
test
```

