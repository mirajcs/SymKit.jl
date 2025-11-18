using Documenter
using SymKit  # Was: VectorUtils

makedocs(
    sitename = "SymKit.jl",
    modules = [SymKit],  # Was: VectorUtils
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md"
    ],
)