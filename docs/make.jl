using Pkg

Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using IncCSV

DocMeta.setdocmeta!(IncCSV, :DocTestSetup, :(using IncCSV); recursive=true)

makedocs(
    modules=[IncCSV],
    authors="Matthew Roughan <matthew.roughan@adelaide.edu.au>",
    sitename="IncCSV.jl",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://matthew.roughan@adelaide.edu.au.github.io/IncCSV.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md", 
        "Metadata Grammar" => "metadata.md",
        "Structure Options" => "structure.md",
        "Mini Schema" => "schema.md",
        "API" => "api.md",
    ],
    remotes=nothing,
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/mroughan/IncCSV.jl",
)
