using Documenter, OceanAnalysis

makedocs(
    sitename="OceanAnalysis",
    modules=[OceanAnalysis],
    pages=[
        "Home" => "index.md",
        "Manual" => "manual.md",
        "API" => "api.md"
    ]
)

