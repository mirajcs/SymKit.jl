# SymKit.jl

A Julia package for symbolic computation. SymKit provides a small expression
tree (`Sym`, `Const`, `UnaryOp`, `BinaryOp`) on which you can build algebraic
expressions, simplify them, differentiate them, evaluate them at numeric
points, and probe their limits at singularities.

## Installation

```julia
using Pkg
Pkg.develop(path="path/to/SymKit")
using SymKit
```

## Quick start

```julia
using SymKit

@sym x

expr = x^2 + 3*x + 2

Simplify(expr)              # x² + 3x + 2
Derivative(expr, x)         # 2x + 3
Evaluate(expr, x, 2)        # Const(12)
```

## Expression types

All symbolic objects are subtypes of `SymExpr`:

| Type       | Role                                | Source                                                                |
|------------|-------------------------------------|-----------------------------------------------------------------------|
| `Sym`      | A named variable (e.g. `x`, `t`)    | [`src/types.jl:6`](https://github.com/mirajcs/SymKit/blob/main/src/types.jl#L6) |
| `Const`    | A wrapped numeric constant          | [`src/types.jl:11`](https://github.com/mirajcs/SymKit/blob/main/src/types.jl#L11) |
| `UnaryOp`  | A unary operation (`-`, `sqrt`, `abs`) | [`src/types.jl:16`](https://github.com/mirajcs/SymKit/blob/main/src/types.jl#L16) |
| `BinaryOp` | A binary operation (`+`, `-`, `*`, `/`, `^`) | [`src/types.jl:22`](https://github.com/mirajcs/SymKit/blob/main/src/types.jl#L22) |

Numeric literals are promoted to `Const` automatically through `promote_expr`
(see [`src/promote.jl`](https://github.com/mirajcs/SymKit/blob/main/src/promote.jl)),
so `2 * x` and `Const(2) * x` are interchangeable.

## Declaring symbols

The `@sym` macro binds one or more symbols in the current scope
(see [`src/macro.jl`](https://github.com/mirajcs/SymKit/blob/main/src/macro.jl)):

```julia
@sym x          # x = Sym(:x)
@sym x y z      # (x, y, z) = (Sym(:x), Sym(:y), Sym(:z))
```

## Arithmetic

Standard arithmetic operators are overloaded for any combination of `SymExpr`
and `Number`, plus unary `-`, `sqrt`, and `abs`
(see [`src/operations.jl`](https://github.com/mirajcs/SymKit/blob/main/src/operations.jl)):

```julia
@sym x
expr = sqrt(x^2 + 1) - abs(x) / 2
```

## Simplification

`Simplify` repeatedly applies one-step rewrites until a fixed point
(see [`src/simplifications.jl:311`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L311)).
The rule set includes:

- Constant folding for `+`, `-`, `*`, `/`, `^` ([`simplifications.jl:68`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L68))
- Identity rules: `x + 0 = x`, `x * 1 = x`, `x * 0 = 0`, `x^0 = 1`, `x^1 = x` ([`simplifications.jl:99`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L99))
- Coefficient folding: `(a*x)*b = (a*b)*x` ([`simplifications.jl:87`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L87))
- Distribution: `a*(b+c) = a*b + a*c` ([`simplifications.jl:54`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L54))
- Like-term combination: `a*x + b*x = (a+b)*x` ([`simplifications.jl:253`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L253))
- Perfect-square recognition: `a² + 2ab + b² = (a+b)²` ([`simplifications.jl:182`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L182))
- `sqrt(x^2) = |x|`, `|-x| = |x|`, double negation ([`simplifications.jl:17`](https://github.com/mirajcs/SymKit/blob/main/src/simplifications.jl#L17))

The rewrite engine is intentionally simple — a term-rewriting fixed-point loop
in the style described by Baader & Nipkow [^baader] and the classical CAS
texts [^cohen][^geddes].

## Differentiation

`Derivative(expr, var)` computes the symbolic derivative and simplifies the
result (see [`src/differentiate.jl:45`](https://github.com/mirajcs/SymKit/blob/main/src/differentiate.jl#L45)).
The implementation is a direct recursive descent over the expression tree,
following the standard rules of single-variable calculus [^stewart]:

| Rule           | Formula                                  |
|----------------|------------------------------------------|
| Constant       | d/dx(c) = 0                              |
| Variable       | d/dx(x) = 1                              |
| Sum            | d/dx(f + g) = f′ + g′                    |
| Difference     | d/dx(f − g) = f′ − g′                    |
| Product        | d/dx(f·g) = f′·g + f·g′                  |
| Quotient       | d/dx(f/g) = (f′·g − f·g′) / g²           |
| Power          | d/dx(fⁿ) = n·fⁿ⁻¹·f′                    |
| sqrt (chain)   | d/dx(√f) = f′ / (2√f)                    |
| abs (chain)    | d/dx(\|f\|) = f′ · sgn(f)                |

```julia
@sym x
Derivative(x^2 + 3*x + 2, x)   # 2x + 3
Derivative(1 / x, x)           # -1 / x²
Derivative(sqrt(x), x)         # 1 / (2√x)
```

## Evaluation

`Evaluate(expr, var, value)` substitutes a numeric value for `var` and
simplifies the result, often collapsing to a single `Const`
(see [`src/evaluate.jl:14`](https://github.com/mirajcs/SymKit/blob/main/src/evaluate.jl#L14)).

```julia
@sym x
Evaluate(x^2 + 3*x + 2, x, 2)   # Const(12)
```

Related helpers:

- `hasVariable(expr, var)` — does `var` appear in `expr`? ([`evaluate.jl:44`](https://github.com/mirajcs/SymKit/blob/main/src/evaluate.jl#L44))
- `Denominator(expr)` — extract the denominator of a top-level division ([`evaluate.jl:69`](https://github.com/mirajcs/SymKit/blob/main/src/evaluate.jl#L69))
- `Singularities(expr, var)` — collect denominators that may vanish ([`evaluate.jl:91`](https://github.com/mirajcs/SymKit/blob/main/src/evaluate.jl#L91))

## Limits

`Limit(expr, var, point; direction, epsilon)` estimates a one- or two-sided
limit numerically by sampling a geometric sequence of test points converging
to `point` and inspecting the tail
(see [`src/limits.jl:25`](https://github.com/mirajcs/SymKit/blob/main/src/limits.jl#L25)).
The approach mirrors the textbook epsilon-based definition [^rudin] rather
than performing symbolic limit calculus, so it is best understood as a
diagnostic for behaviour near a point.

```julia
@sym x
Limit(1/x, x, 0; direction=:left)    # :-inf
Limit(1/x, x, 0; direction=:right)   # :inf
Limit(1/x, x, 0)                     # (:-inf, :inf)
```

`CheckDivisionLimits` scans integer test points in `-10:10`, identifies where
a denominator becomes (numerically) zero, and reports the left and right
limits at each candidate singularity
([`limits.jl:99`](https://github.com/mirajcs/SymKit/blob/main/src/limits.jl#L99)).
`DivisionBehavior` formats that result as a human-readable string
([`limits.jl:154`](https://github.com/mirajcs/SymKit/blob/main/src/limits.jl#L154)).

## Pretty printing

`Base.show` is overloaded for each expression type to render expressions
closer to mathematical notation: unicode radicals (`√‾x‾`), absolute-value
bars (`|x|`), superscript integer exponents (`x²`), and compact
multiplication (`4x` instead of `(4 * x)`). See
[`src/prettyprinting.jl`](https://github.com/mirajcs/SymKit/blob/main/src/prettyprinting.jl).

## Worked example

A kinematics example from [`examples/13_4.jl`](https://github.com/mirajcs/SymKit/blob/main/examples/13_4.jl)
— velocity and acceleration of a particle on the path `r(t) = ⟨t³, t²⟩` at
`t = 1`:

```julia
using SymKit
@sym t

r(t)         = [t^3, t^2]
first_der(t) = [Derivative(r(t)[i], t) for i in 1:length(r(t))]
acc(t)       = [Derivative(first_der(t)[i], t) for i in 1:length(r(t))]

velocity_at_1     = [Evaluate(first_der(t)[i], t, 1) for i in 1:length(first_der(t))]
acceleration_at_1 = [Evaluate(acc(t)[i], t, 1)       for i in 1:length(acc(t))]
```

## Author

**Miraj Samarakkody** — <miraj.samarakkody@gmail.com>

Source: <https://github.com/mirajcs/SymKit>

## Citing SymKit.jl

If you use SymKit.jl in your work, please cite it as:

> Samarakkody, M. (2025). *SymKit.jl: A Julia package for symbolic computation* (Version 0.1.0) [Computer software]. https://github.com/mirajcs/SymKit

BibTeX:

```bibtex
@software{samarakkody_symkit_2025,
  author  = {Samarakkody, Miraj},
  title   = {{SymKit.jl}: A {J}ulia package for symbolic computation},
  year    = {2026},
  version = {0.1.0},
  url     = {https://github.com/mirajcs/SymKit}
}
```

## References

[^stewart]: Stewart, J. *Calculus: Early Transcendentals*, 8th ed. Cengage Learning, 2015. — Differentiation rules used in [`src/differentiate.jl`](https://github.com/mirajcs/SymKit/blob/main/src/differentiate.jl).

[^rudin]: Rudin, W. *Principles of Mathematical Analysis*, 3rd ed. McGraw-Hill, 1976. — ε-δ formulation underlying the numerical `Limit` routine.

[^cohen]: Cohen, J. S. *Computer Algebra and Symbolic Computation: Mathematical Methods*. A K Peters, 2003. — Expression-tree representation and simplification strategy.

[^geddes]: Geddes, K. O.; Czapor, S. R.; Labahn, G. *Algorithms for Computer Algebra*. Kluwer, 1992. — General reference for symbolic simplification and canonicalization.

[^baader]: Baader, F.; Nipkow, T. *Term Rewriting and All That*. Cambridge University Press, 1998. — Theoretical basis for the fixed-point rewrite loop in `Simplify`.
