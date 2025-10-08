# OceanAnalysis.jl

[![AutoMerge](https://github.com/JuliaRegistries/General/actions/workflows/automerge.yml/badge.svg)](https://github.com/JuliaRegistries/General/actions/workflows/automerge.yml)

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at an early stage of development, and it is developed
using the "dog food" method, in which changes and additions are guided by the
author's everyday work.

Please note that this README file is just a landing page for GitHub perusal.
The full documentation is available [online](https://dankelley.github.io/OceanAnalysis.jl/dev/).

## Installation

### Official version

The official version may be installed by typing the following in a Julia
console.

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

### Semi-stable development version

The version under development may be installed by typing the following in a
Julia console.

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
```

### Author's unstable version

The author installs from local source (which may include things not yet pushed
to the GitHub site) by typing the following in a Julia console.

```julia
cd ~/git/OceanAnalysis.jl
] develop .
```

A similar strategy could be used by users who are planning to add to the
package development by making a pull request.
