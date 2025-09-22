# OceanAnalysis.jl

OceanAnalysis.jl is a Julia package designed to facilitate the analysis of
oceanographic data. It is at an early stage of development by someone who is in
the early stages of exploring Julia as a supplement to R. The intention is to
add/refine features based on tasks that come up in the author's everyday work.

Please note that this README file is just a landing page for GitHub perusal.
Full documentation is available online at
[https::dankelley.github.io/OceanAnalysis.jl/dev/](https::dankelley.github.io/OceanAnalysis.jl/dev).

## Installation

### Official version

Once (if) the package is accepted by the Julia archive system, you may install
it by typing the following in a Julia console.

```julia
using Pkg ; Pkg.add("OceanAnalysis")
```

(This version will lag quite far behind the development version.)

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
development website.  This is updated very frequently, because the author tests
changes using this method.

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl", rev="develop")
```

#### Brittle (for the core developer)

In the commandline, navigate to the local source for the library.  Then start
a Julia console and type the following.

```julia
]
develop .
```

This sets Julia to look for changes in the files in that directory. Thereafter,
or at least until another `Pkg.add(url)` command is invoked, issuing `using
OceanAnalysis` in a Julia session will rebuild from that local source.

