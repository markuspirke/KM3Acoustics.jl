using Documenter, KM3Acoustics

makedocs(;
    modules=[KM3Acoustics],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        assets=String[],
    ),
    pages=[
        "Introduction" => "index.md",
        "Example Usage" => "exampleusage.md",
        "APIs" => "internalapis.md",
    ],
    repo="https://github.com/mpirke/KM3Acoustics.jl/blob/{commit}{path}#L{line}",
    sitename="KM3Acoustics.jl",
    authors="Markus Pirke",
)

deploydocs(;
    repo="github.com/mpirke/KM3Acoustics.jl",
)
