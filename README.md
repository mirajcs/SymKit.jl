# SymKit.jl

A Julia package for symbolic computation. SymKit provides a small expression
tree (`Sym`, `Const`, `UnaryOp`, `BinaryOp`) on which you can build algebraic
expressions, simplify them, differentiate them, evaluate them at numeric
points, and probe their limits at singularities.

## Installation

Once registered in the Julia General registry:

```julia
using Pkg
Pkg.add("SymKit")
```

From source:

```julia
using Pkg
Pkg.add(url="https://github.com/mirajcs/SymKit")
```

## Quick start

```julia
using SymKit

@sym x

expr = x^2 + 3*x + 2

Simplify(expr)            # x² + 3x + 2
Derivative(expr, x)       # 2x + 3
Evaluate(expr, x, 2)      # Const(12)
```

## Features

- Symbolic expressions over `+`, `-`, `*`, `/`, `^`, `sqrt`, `abs`
- Term-rewriting `Simplify` with constant folding, distribution, like-term
  combination, and perfect-square recognition
- Symbolic `Derivative` via sum/product/quotient/power/chain rules
- `Evaluate` for numeric substitution
- Numerical `Limit`, `CheckDivisionLimits`, and `DivisionBehavior` for
  exploring one- and two-sided behaviour at singularities
- Unicode pretty-printing (`x²`, `√‾x‾`, `|x|`, `4x`)

## Documentation

Full documentation, including the differentiation-rule table, source-level
citations, and references, lives in [`docs/src/index.md`](docs/src/index.md).

## Citing SymKit.jl

```bibtex
@software{samarakkody_symkit_2026,
  author  = {Samarakkody, Miraj},
  title   = {{SymKit.jl}: A {J}ulia package for symbolic computation},
  year    = {2026},
  version = {0.1.0},
  doi     = {10.5281/zenodo.20237362},
  url     = {https://github.com/mirajcs/SymKit}
}
```

## Acknowledgement

This work was supported by the HBCU UP Implementation project, Award No. 2510537.

## License

MIT — see [LICENSE](LICENSE).
