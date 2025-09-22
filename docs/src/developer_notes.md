# Developer Notes

## Installation methods

### Setup to use the GH "main" branch version

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
```

### Setup to use the GH "develop" branch version

```julia
using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl", rev="develop")
```

### Setup to use the local version

In the commandline, navigate to the local source for the library, then enter
the following .  Then start a Julia console and type the following.

```julia
]
develop .
```

## Adding a package dependency

For example, to add `Downloads` as a dependency to the present package,
navigate to the present-package source directory, start a Julia session, and
type the following.

```julia
]
activate . # the "." is crucial ... I keep forgetting this
add Downloads
# do we need to instantiate now?
```

## Running tests

There is a small test suite built into the package.  To run it, type the
following in a Julia console:

```julia
]
activate .
test OceanAnalysis
```

## Building and viewing documentation on development machine

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

NOTE: I don't yet know how to host the documentation on GH.
