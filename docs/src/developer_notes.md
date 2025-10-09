# Developer Notes

## Building locally

To avoid too much pressure on github and too much confusion amongst
users, build and test locally before pushing to github.  To set this up,
simply navigate to the source directory, enter Julia, and type the following.

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

## Updating documentation locally

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

## Updating documentation on github

Pushing to the "main" branch will cause the remote (github) machine to build up
the documentation and push it to the "gh-pages" branch.  No action is required
on the developer's part except for pushing to "main".
