# Some of the contents of the present file mimic a corresponding make.jl file,
# https://github.com/ufechner7/FLORIDyn.jl/blob/main/docs/make.jl, the author
# of which patiently and generously helped me to learn how to build Julia
# documentation.

# Next from https://raw.githubusercontent.com/JuliaManifolds/Manopt.jl/72ecc6d72bc191de273506af75bef215fc836191/docs/make.jl
if Base.active_project() != joinpath(@__DIR__, "Project.toml")
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.develop(PackageSpec(; path=(@__DIR__) * "/../"))
    Pkg.resolve()
    Pkg.instantiate()
end

using Documenter, OceanAnalysis

DocMeta.setdocmeta!(OceanAnalysis, :DocTestSetup, :(using OceanAnalysis); recursive=true)

makedocs(;
    modules=[OceanAnalysis],
    authors="Dan Kelley",
    repo=Documenter.Remotes.GitHub("dankelley", "OceanAnalysis.jl"),
    #repo="https://github.com/dankelley/OceanAnalysis.jl/blob/{commit}{path}#{line}",
    sitename="OceanAnalysis.jl",
    checkdocs=:none,
    format=Documenter.HTML(;
        assets=String["assets/custom.css"],
        canonical="https::dankelley.github.io/OceanAnalysis.jl/dev/",
        repolink="https://github.com/dankelley/OceanAnalysis.jl",
        prettyurls=get(ENV, "CI", "false") == "true",
    ),
    pages=[
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Examples" => "examples.md",
        "Data Types" => "data_types.md",
        "Function Reference" => "functions.md",
        "Changelog" => "changelog.md",
        "Developer Notes" => "developer_notes.md"
    ],
)

deploydocs(;
    repo="github.com/dankelley/OceanAnalysis.jl",
    devbranch="main",
    push_preview=true,
)
