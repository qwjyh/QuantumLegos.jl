#! format: off
using QuantumLegos
using Documenter

DocMeta.setdocmeta!(QuantumLegos, :DocTestSetup, :(using QuantumLegos); recursive=true)

makedocs(;
    modules=[QuantumLegos],
    authors="",
    # repo="",
    sitename="QuantumLegos.jl",
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
