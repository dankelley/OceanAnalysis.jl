# Installation methods

The official version may be installed by typing the following in a Julia
console.

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

The version under development may be installed by typing the following in a
Julia console.

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
```


The author installs from local source (which may include things not yet pushed
to the GitHub site) by typing the following in a Julia console.

```julia
cd ~/git/OceanAnalysis.jl
] develop .
```

A similar strategy could be used by users who are planning to add to the
package development by making a pull request.
