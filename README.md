# OceanAnalysis.jl

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at a very early stage of development by someone who
is in the early steps of exploring Julia as a supplement to R.

## Installation

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

### Official version

Start Julia and enter the following:

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

## Usage Example

```julia
using OceanAnalysis
S = [30.0;32.0]
T = [15.0;10.0]
p = [0.0;100.0]
ctd = Ctd(S, T, p, -50.0, 40.0)
plotTS(ctd)
```

## History of breaking changes

* None.

## History of changes

### 0.0.3 (in development)

#### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

#### Non-breaking changes

* Add built-in data file `ctd.cnv.nc`, and use it in an example in the `Ctd()` documentation.
* Add built-in data file `D4902911_095.nc`, and use it in an example in the `plotProfile()` documentation.
* `getElement()` can now return `"N2"`.
* `plotProfile()` can now plot `N2"`.

### 0.0.2

#### Breaking changes

There are no breaking changes; all change are additions or bug fixes.

#### Non-breaking changes

* Add `N2()` to compute the square of the buoyancy frequency.
