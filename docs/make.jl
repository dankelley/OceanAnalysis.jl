using Documenter, OceanAnalysis
makedocs(;
    modules=[OceanAnalysis],
    authors="Dan Kelley",
    repo=Documenter.Remotes.GitHub("dankelley", "OceanAnalysis.jl"),
    sitename="OceanAnalysis.jl",
    checkdocs=:none,
    format=Documenter.HTML(;
      assets = String["assets/custom.css"],
      canonical = "https::dankelley.github.io/OceanAnalysis.jl/dev/",
      repolink = "https::dankelley.github.io/OceanAnalysis.jl/dev/",
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => "manual.md",
        "Examples" => "examples.md",
        "API" => "api.md"
    ]
)

# mimic https://github.com/ufechner7/FLORIDyn.jl/blob/main/docs/make.jl
deploydocs(;
    repo="github.com/dankelley/OceanAnalysis.jl.git",
    devbranch="main",
    push_preview=true,
)
