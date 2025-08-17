# OceanAnalysis.jl

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at a very early stage of development by someone who
is in the early steps of exploring Julia as a supplement to R.

## Installation

### Development version

Start Julia and enter the following:

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
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

## History of major changes

### 0.0.3 (in development)

* Change `plotProfile()` to accept `which="N2"` for plotting the square of the
  buoyancy frequency.

### 0.0.2

* Add `N2()` to compute the square of the buoyancy frequency.
