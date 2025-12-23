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

## Updating on julia registry

1. Test locally with `] activate .` followed by `test`. Exit from the packager
   with control-C and then from Julia.  Then fix any problems that were noted
   and rerun this step.

2. Build and examine the documentation locally (see above).

3. Push to GitHub.

4. Use the package for a few days or weeks to be sure that the changes are
   good. Be sure to follow the above steps for each change that is required.
   (For example, don't forget to examine and evaluate the documentation for
   each change.)

5. When you think that things are stable, i.e. that no breaking changes will be
   required in the future, go to the GitHub website and insert a comment on the
   latest commit. The details of the comment *must* be in a particular format,
   as exemplified below.  (For example, I wasted a lot of time not realizing
   that a colon was required at the end of the 'Release notes:' line.)

```
@JuliaRegistrator register

Release notes:

### Changed
- [`as_ctd`](@ref) accepts ranges as well as vectors for `salinity`, `temperature` and `pressure`.
- [`coastline`](@ref) accepts ranges for `longitude` and `latitude`, in addition to vectors.
- [`coastline`](@ref) on a CSV file throws an error if columns named "longitude" and "latitude" are not found.
- BREAKING: none

### Added
- The Examples tab of the online documentation shows hot to create an Argo-trajectory map.
- [`as_section`](@ref) assembles CTD profiles into an oceanographic section.
- [`coriolis`](@ref) computes the Coriolis parameter.
- [`gravity`](@ref) computes the acceleration due to earth gravity.
- [`scale_bar`](@ref) adds a scale bar to a map plot.
```

NB. the TagBot action (in .github/Workflows) automatically creates a tag, so there's no need to do that manually.

About half an hour after doing the above, check
https://github.com/JuliaRegistries/General/tree/master/O to see if a new
version has appeared.
