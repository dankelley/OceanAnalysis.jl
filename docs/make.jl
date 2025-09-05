push!(LOAD_PATH, "../src/")
using Documenter
using OceanAnalysis
makedocs(
    #repo=Documenter.Remotes.GitHub("dankelley", "OceanAnalysis.jl"),
    sitename="OceanAnalysis.jl Documentation",
    modules=OceanAnalysis,
    #authors="Dan Kelley",
    pages=[
        "Home" => "index.md"
        #"Home" => "index.md",
        #"Manual" => "manual.md",
        #"API" => "api.md"
    ]
)
deploydocs(
    repo="github.com/dankelley/OceanAnalysis.jl",
)
