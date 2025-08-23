# OceanAnalysis.jl

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at a very early stage of development by someone who
is in the early steps of exploring Julia as a supplement to R.

## Installation

### Official version

Start Julia and enter the following:

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

### Development version

#### Relatively stable (for users)

Start Julia and enter the following:

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
```

#### Unstable (for developers)

Start Julia and enter the following:

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl", rev="develop")
```

## Usage Example

```julia
# Read a built-in CTD file, and plot a profile of Absolute Salinity
using OceanAnalysis, Plots, Measures
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
filename = joinpath(pkgdir, "data", "ctd.cnv")
ctd = readCtdCNV(filename, !true)
p1 = plotProfile(ctd, "SA")
p2 = plotProfile(ctd, "CT")
p3 = plotTS(ctd)
plot(p1, p2, p3, layout=(1, 3), size=(800, 400), margin = 0.25cm)
```

![Example plot](example.png)

## Development testing

```julia
using Pkg
Pkg.activate(".")
Pkg.test()
```

## History of breaking changes

* None.

## History of changes

### 0.0.3 (in development)

#### 0.0.3 Breaking changes

There are no breaking changes; all change are additions or bug fixes.

#### 0.0.3 Non-breaking changes

* Add built-in data file `ctd.cnv.nc`, and use it in an example in the `Ctd()` documentation.
* Add built-in data file `D4902911_095.nc`, and use it in an example in the `plotProfile()` documentation.
* `getElement()` can now return `"N2"`.
* `plotProfile()` can now plot `N2"`.

### 0.0.2

#### 0.0.2 Breaking changes

There are no breaking changes; all change are additions or bug fixes.

#### 0.0.2 Non-breaking changes

* Add `N2()` to compute the square of the buoyancy frequency.
