using OptiGraphsBase
using Documenter

DocMeta.setdocmeta!(OptiGraphsBase, :DocTestSetup, :(using OptiGraphsBase); recursive=true)

makedocs(;
    modules=[OptiGraphsBase],
    authors="jalving <jhjalving@gmail.com> and contributors",
    sitename="OptiGraphsBase.jl",
    format=Documenter.HTML(;
        canonical="https://jalving.github.io/OptiGraphsBase.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jalving/OptiGraphsBase.jl",
    devbranch="main",
)
