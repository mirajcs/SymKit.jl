# SymKit Limits and Division Analysis Guide

## Overview

SymKit now supports analyzing division by zero scenarios and calculating left and right-handed limits at singularities. This is essential for understanding the behavior of rational functions and identifying discontinuities.

## Key Features

### 1. Expression Evaluation
Substitute variable values into expressions to compute numerical results.

```julia
@sym x
expr = x^2 + 3*x + 2
result = evaluate(expr, x, 2)  # Returns Const(12)
```

### 2. Variable Detection
Check if an expression contains a specific variable.

```julia
has_variable(x + y, x)  # Returns true
has_variable(Const(5), x)  # Returns false
```

### 3. Denominator Extraction
Extract the denominator from division expressions.

```julia
expr = (x + 1) / (x - 1)
denom = get_denominator(expr)  # Returns (x - 1)
```

### 4. Singularity Detection
Find all divisions in an expression that could have singularities.

```julia
expr = 1 / (x - 2)
sings = find_singularities(expr, x)  # Identifies divisions
```

### 5. Limit Calculation with Direction Control

Calculate limits as a variable approaches a point from specific directions:

```julia
expr = 1 / x

# Left-handed limit (x → 0⁻)
left_lim = limit(expr, x, 0; direction=:left)  # Returns Symbol("-inf")

# Right-handed limit (x → 0⁺)
right_lim = limit(expr, x, 0; direction=:right)  # Returns :inf

# Both directions
both = limit(expr, x, 0; direction=:both)  # Returns (Symbol("-inf"), :inf)
```

### 6. Comprehensive Division Analysis

Analyze all division singularities in an expression:

```julia
expr = 1 / x
analysis = check_division_limits(expr, x)

# Returns a dictionary with:
# :has_singularity => true/false
# :singularities => [
#   {
#     :point => 0,
#     :left_limit => Symbol("-inf"),
#     :right_limit => :inf,
#     :continuous => false
#   }
# ]
```

### 7. Human-Readable Descriptions

Get detailed descriptions of discontinuities and limit behavior:

```julia
expr = 1 / x
description = describe_division_behavior(expr, x)
# Output: "At x=0: Discontinuous - Left limit: -∞, Right limit: +∞"
```

## Common Use Cases

### Case 1: Simple Hyperbola (1/x)
**Behavior**: Vertical asymptote at x=0 with opposite infinity on each side

```julia
@sym x
expr = 1 / x

# Check limits
left_lim = limit(expr, x, 0; direction=:left)   # -∞
right_lim = limit(expr, x, 0; direction=:right) # +∞

# Describe behavior
describe_division_behavior(expr, x)
# "At x=0: Discontinuous - Left limit: -∞, Right limit: +∞"
```

### Case 2: Rational Function with Multiple Singularities
**Behavior**: 1/(x²-1) has singularities at both x=1 and x=-1

```julia
@sym x
expr = 1 / (x^2 - 1)

analysis = check_division_limits(expr, x)
# Identifies both x=1 and x=-1 as singularities
# Shows that both have left_limit = -∞ and right_limit = +∞
```

### Case 3: Removable Singularity
**Behavior**: (x²-1)/(x-1) has a "hole" at x=1 (can be removed by canceling)

```julia
@sym x
expr = (x^2 - 1) / (x - 1)

left_lim = limit(expr, x, 1; direction=:left)   # 2
right_lim = limit(expr, x, 1; direction=:right) # 2

# Even though the denominator is 0 at x=1, the limits are equal
# This is a removable singularity
```

### Case 4: Polynomial (No Division)
**Behavior**: Continuous everywhere

```julia
@sym x
expr = x^2 + 2*x + 1

analysis = check_division_limits(expr, x)
# :has_singularity => false
# No discontinuities detected
```

## Function Reference

### `evaluate(expr::SymExpr, var::Sym, value::Number)`
Substitute a variable with a numeric value and evaluate the expression.

**Parameters:**
- `expr`: Expression to evaluate
- `var`: Symbol to substitute
- `value`: Numeric value to substitute

**Returns:** Simplified symbolic expression (may be a `Const` if fully evaluated)

### `has_variable(expr::SymExpr, var::Sym)`
Check if an expression contains a specific variable.

**Parameters:**
- `expr`: Expression to check
- `var`: Variable to search for

**Returns:** Boolean

### `get_denominator(expr::SymExpr)`
Extract the denominator from a division expression.

**Parameters:**
- `expr`: Expression to analyze

**Returns:** Denominator (or `nothing` if not a division)

### `find_singularities(expr::SymExpr, var::Sym)`
Find all divisions in an expression.

**Parameters:**
- `expr`: Expression to analyze
- `var`: Variable to consider (for future root-finding)

**Returns:** Vector of denominators that could be zero

### `limit(expr::SymExpr, var::Sym, point::Number; direction=:both, epsilon=1e-6)`
Calculate the limit of an expression as a variable approaches a point.

**Parameters:**
- `expr`: Expression to evaluate
- `var`: Variable approaching the point
- `point`: Point being approached
- `direction`: `:left`, `:right`, or `:both`
- `epsilon`: Step size for numerical approximation

**Returns:**
- For directional limits: `:inf`, `Symbol("-inf")`, `:undefined`, `:nan`, or `Const(value)`
- For `:both`: Tuple of `(left_limit, right_limit)`

### `check_division_limits(expr::SymExpr, var::Sym; epsilon=1e-6)`
Analyze all division singularities in an expression.

**Parameters:**
- `expr`: Expression to analyze
- `var`: Variable to consider
- `epsilon`: Step size for numerical approximation

**Returns:** Dictionary with keys:
- `:has_singularity::Bool` - Whether singularities exist
- `:singularities::Vector` - List of singularity info (point, left_limit, right_limit, continuous)

### `describe_division_behavior(expr::SymExpr, var::Sym)`
Generate a human-readable description of division behavior.

**Parameters:**
- `expr`: Expression to analyze
- `var`: Variable to consider

**Returns:** String description

## Implementation Details

### Limit Calculation Algorithm
The limit calculation uses a numerical convergence approach:

1. Evaluate the expression at points converging to the target from the specified direction
2. Use a geometric sequence: `point + step / (2^i)` for `i = 1, 2, 3, ...`
3. Analyze the sequence of results to determine if:
   - The limit is a finite value
   - The limit diverges to positive infinity
   - The limit diverges to negative infinity
   - The limit is undefined

### Singularity Detection
Singularities are found by:

1. Recursively traversing the expression tree
2. Identifying all division operations
3. For each denominator, sampling points to find zeros
4. Computing left and right limits at each zero

### Limitations
- Numerical limits are approximations and may not be exact for all functions
- Requires differentiable/evaluable functions
- May not detect all singularities in complex nested expressions
- Epsilon parameter affects accuracy and computation time

## Examples

See `examples/limits_demo.jl` for a comprehensive demonstration of all functionality.

Run it with:
```julia
julia examples/limits_demo.jl
```

## Testing

Comprehensive test suite in `test/runtests.jl` covers:
- Basic evaluation
- Polynomial evaluation
- Variable detection
- Denominator extraction
- Limit calculations (left, right, both)
- Division analysis
- Singularity detection
- Edge cases

All tests pass with 23/23 test cases.

## Future Enhancements

Potential improvements:
1. **Symbolic root finding**: Analytically find zeros of polynomial denominators
2. **Asymptote detection**: Identify and describe vertical, horizontal, and oblique asymptotes
3. **Continuity analysis**: Classify singularities as removable, jump, or infinite
4. **Graphical visualization**: Plot functions with marked singularities
5. **Series expansion**: Taylor/Laurent series around singularities
