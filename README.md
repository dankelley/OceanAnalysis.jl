# OceanAnalysis

OceanAnalysis.jl is a package designed to facilitate the analysis of
oceanographic data. It is at a very early stage of development by someone who
is much more familiar with R than with Julia.

## Installation

Start Julia and enter the following:

```julia
using Pkg
Pkg.add("OceanAnalysis")
```

# Example

```julia
using OceanAnalysis
S = [30;32]
T = [15;10]
p = [0;100]
ctd = Ctd(S, T, p)
plotTS(ctd)
```
