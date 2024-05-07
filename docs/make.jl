#! format: off
using Legos
using Documenter

DocMeta.setdocmeta!(Legos, :DocTestSetup, :(using Legos); recursive=true)

makedocs(;
    modules=[Legos],
    authors="",
    # repo="",
    sitename="Legos.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "PauliOps" => "pauliops.md",
        "checkmatrix.md",
        "distance.md",
    ],
)
