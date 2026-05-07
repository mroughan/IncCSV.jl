using Pkg

Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using IncCSV

DocMeta.setdocmeta!(IncCSV, :DocTestSetup, :(using IncCSV); recursive=true)

makedocs(
    sitename="IncCSV.jl",
    modules=[IncCSV],
    pages=[
        "Home" => "index.md",
        "Metadata Grammar" => "metadata.md",
        "Mini Schema" => "schema.md",
        "API" => "api.md",
    ],
    remotes=nothing,
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link=nothing,
        repolink=nothing,
    ),
    checkdocs=:exports,
)
