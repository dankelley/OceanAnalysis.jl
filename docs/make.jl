#push!(LOAD_PATH, "../src/")
using Documenter, OceanAnalysis
makedocs(
    modules=[OceanAnalysis],
    repo=Documenter.Remotes.GitHub("dankelley", "OceanAnalysis.jl"),
    sitename="OceanAnalysis.jl",
    authors="Dan Kelley",
    pages=[
        "Home" => "index.md",
        #"Manual" => "manual.md",
        "Examples" => "examples.md",
        "API" => "api.md"
    ]
)

# mimic https://github.com/ufechner7/FLORIDyn.jl/blob/main/docs/make.jl
deploydocs(;
    repo="github.com/dankelley/OceanAnalysis.jl.git",
    devbranch="main",
    push_preview=true
    #target="build",
    #branch = "gh-pages"
    #deps=nothing,
    #make=nothing,
)
