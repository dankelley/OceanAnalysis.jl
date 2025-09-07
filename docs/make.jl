#push!(LOAD_PATH, "../src/")
using Documenter, OceanAnalysis
makedocs(
    modules=[OceanAnalysis],
    repo=Documenter.Remotes.GitHub("dankelley", "OceanAnalysis.jl"),
    sitename="OceanAnalysis.jl",
    authors="Dan Kelley",
    pages=[
        "Home" => "index.md",
        "Manual" => "manual.md",
        "API" => "api.md"
    ]
)
deploydocs(
    repo="github.com/dankelley/OceanAnalysis.jl.git",
    target="build",
    deps=nothing,
    make=nothing,
    push_preview=true
)
