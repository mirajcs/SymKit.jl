# Internal helper function - applies one simplification rule
# Using multiple dispatch for different expression types

# Base cases: Sym and Const are already simplified
simplify_once(expr::Sym) = expr
simplify_once(expr::Const) = expr

# Simplify UnaryOp - dispatch to specific handler
simplify_once(expr::UnaryOp) = simplify_unary(expr)

# Simplify BinaryOp - dispatch to specific handler
simplify_once(expr::BinaryOp) = simplify_binary(expr)

# Simplify unary operations
function simplify_unary(expr::UnaryOp)
    arg = simplify_once(expr.arg)

    # Double negation: -(-x) = x
    if expr.op == :- && arg isa UnaryOp && arg.op == :-
        return arg.arg
    end

    # Constant simplification for sqrt: sqrt(4) = 2
    if expr.op == :sqrt && arg isa Const && arg.value >= 0
        return Const(sqrt(arg.value))
    end

    # sqrt(x^2) = abs(x)
    if expr.op == :sqrt && arg isa BinaryOp && arg.op == :^
        if arg.right isa Const && arg.right.value == 2
            return UnaryOp(:abs, arg.left)
        end
    end

    # Constant simplification for abs: abs(-5) = 5
    if expr.op == :abs && arg isa Const
        return Const(abs(arg.value))
    end

    # abs(-x) = abs(x)
    if expr.op == :abs && arg isa UnaryOp && arg.op == :-
        return UnaryOp(:abs, arg.arg)
    end

    # Trigonometric constant simplifications
    if expr.op == :sin && arg isa Const
        return Const(sin(arg.value))
    end

    if expr.op == :cos && arg isa Const
        return Const(cos(arg.value))
    end

    if expr.op == :tan && arg isa Const
        return Const(tan(arg.value))
    end

    # Inverse trigonometric constant simplifications
    if expr.op == :asin && arg isa Const && abs(arg.value) <= 1
        return Const(asin(arg.value))
    end

    if expr.op == :acos && arg isa Const && abs(arg.value) <= 1
        return Const(acos(arg.value))
    end

    if expr.op == :atan && arg isa Const
        return Const(atan(arg.value))
    end

    # Exponential and logarithmic constant simplifications
    if expr.op == :exp && arg isa Const
        return Const(exp(arg.value))
    end

    if expr.op == :log && arg isa Const && arg.value > 0
        return Const(log(arg.value))
    end

    # Trigonometric identities
    # sin(-x) = -sin(x)
    if expr.op == :sin && arg isa UnaryOp && arg.op == :-
        return simplify_once(-(UnaryOp(:sin, arg.arg)))
    end

    # cos(-x) = cos(x)
    if expr.op == :cos && arg isa UnaryOp && arg.op == :-
        return UnaryOp(:cos, arg.arg)
    end

    # tan(-x) = -tan(x)
    if expr.op == :tan && arg isa UnaryOp && arg.op == :-
        return simplify_once(-(UnaryOp(:tan, arg.arg)))
    end

    # Inverse composition: asin(sin(x)) = x (simplified, ignoring domain)
    if expr.op == :asin && arg isa UnaryOp && arg.op == :sin
        return arg.arg
    end

    if expr.op == :acos && arg isa UnaryOp && arg.op == :cos
        return arg.arg
    end

    if expr.op == :atan && arg isa UnaryOp && arg.op == :tan
        return arg.arg
    end

    if expr.op == :sin && arg isa UnaryOp && arg.op == :asin
        return arg.arg
    end

    if expr.op == :cos && arg isa UnaryOp && arg.op == :acos
        return arg.arg
    end

    if expr.op == :tan && arg isa UnaryOp && arg.op == :atan
        return arg.arg
    end

    # Exponential and logarithmic identities
    # log(exp(x)) = x
    if expr.op == :log && arg isa UnaryOp && arg.op == :exp
        return arg.arg
    end

    # exp(log(x)) = x
    if expr.op == :exp && arg isa UnaryOp && arg.op == :log
        return arg.arg
    end

    # log(1) = 0
    if expr.op == :log && arg isa Const && arg.value == 1
        return Const(0)
    end

    # exp(0) = 1
    if expr.op == :exp && arg isa Const && arg.value == 0
        return Const(1)
    end

    # log(x^n) = n*log(x)
    if expr.op == :log && arg isa BinaryOp && arg.op == :^
        return simplify_once(arg.right * UnaryOp(:log, arg.left))
    end

    return UnaryOp(expr.op, arg)
end

# Simplify binary operations
function simplify_binary(expr::BinaryOp)
    # Check distributive rules BEFORE simplifying operands
    # This ensures we catch patterns like a*(b+c) even if b+c doesn't simplify
    if expr.op == :* && expr.right isa BinaryOp && expr.right.op == :+
        # left * (right.left + right.right) = left * right.left + left * right.right
        return simplify_once((expr.left * expr.right.left) + (expr.left * expr.right.right))
    end

    if expr.op == :* && expr.left isa BinaryOp && expr.left.op == :+
        # (left.left + left.right) * right = left.left * right + left.right * right
        return simplify_once((expr.left.left * expr.right) + (expr.left.right * expr.right))
    end

    left = simplify_once(expr.left)
    right = simplify_once(expr.right)

    # Constant folding: if both sides are constants, compute the result
    if left isa Const && right isa Const
        if expr.op == :+
            return Const(left.value + right.value)
        elseif expr.op == :-
            return Const(left.value - right.value)
        elseif expr.op == :*
            return Const(left.value * right.value)
        elseif expr.op == :/
            # Check for division by zero
            if right.value == 0
                throw(ErrorException("Division by zero"))
            end
            return Const(left.value / right.value)
        elseif expr.op == :^
            return Const(left.value ^ right.value)
        end
    end

    # Coefficient multiplication: (a * x) * b = (a * b) * x
    if expr.op == :* && left isa BinaryOp && left.op == :* && left.left isa Const && right isa Const
        coeff = Const(left.left.value * right.value)
        return simplify_once(coeff * left.right)
    end

    # Coefficient multiplication: a * (b * x) = (a * b) * x
    if expr.op == :* && left isa Const && right isa BinaryOp && right.op == :* && right.left isa Const
        coeff = Const(left.value * right.left.value)
        return simplify_once(coeff * right.right)
    end

    # Identity rules
    if expr.op == :+
        (left isa Const && left.value == 0) && return right
        (right isa Const && right.value == 0) && return left
    end

    if expr.op == :*
        (left isa Const && left.value == 0) && return Const(0)
        (right isa Const && right.value == 0) && return Const(0)
        (left isa Const && left.value == 1) && return right
        (right isa Const && right.value == 1) && return left
    end

    if expr.op == :-
        (right isa Const && right.value == 0) && return left
    end

    if expr.op == :/
        (right isa Const && right.value == 1) && return left
    end

    if expr.op == :^
        (right isa Const && right.value == 0) && return Const(1)
        (right isa Const && right.value == 1) && return left
        # (x^a)^b = x^(a*b)
        if left isa BinaryOp && left.op == :^
            return simplify_once(left.left ^ (left.right * right))
        end
        # exp(a)^b = exp(a*b)
        if left isa UnaryOp && left.op == :exp
            return simplify_once(UnaryOp(:exp, left.arg * right))
        end
        # x^0 = 1 (already handled above with Const check)
        # 0^x = 0 for x > 0
        if left isa Const && left.value == 0 && right isa Const && right.value > 0
            return Const(0)
        end
        # 1^x = 1
        if left isa Const && left.value == 1
            return Const(1)
        end
    end

    # Power rules with multiplication
    # x^a * x^b = x^(a+b)
    if expr.op == :* && left isa BinaryOp && left.op == :^ &&
       right isa BinaryOp && right.op == :^ && left.left == right.left
        return simplify_once(left.left ^ (left.right + right.right))
    end

    # x * x^a = x^(1+a)
    if expr.op == :* && right isa BinaryOp && right.op == :^ && left == right.left
        return simplify_once(left ^ (Const(1) + right.right))
    end

    # x^a * x = x^(a+1)
    if expr.op == :* && left isa BinaryOp && left.op == :^ && right == left.left
        return simplify_once(right ^ (left.right + Const(1)))
    end

    # Division rules
    # x^a / x^b = x^(a-b)
    if expr.op == :/ && left isa BinaryOp && left.op == :^ &&
       right isa BinaryOp && right.op == :^ && left.left == right.left
        return simplify_once(left.left ^ (left.right - right.right))
    end

    # x / x^a = x^(1-a)
    if expr.op == :/ && right isa BinaryOp && right.op == :^ && left == right.left
        return simplify_once(left ^ (Const(1) - right.right))
    end

    # x^a / x = x^(a-1)
    if expr.op == :/ && left isa BinaryOp && left.op == :^ && right == left.left
        return simplify_once(right ^ (left.right - Const(1)))
    end

    # x / x = 1
    if expr.op == :/ && left == right
        return Const(1)
    end

    # Exponential rules
    # exp(a) * exp(b) = exp(a+b)
    if expr.op == :* && left isa UnaryOp && left.op == :exp &&
       right isa UnaryOp && right.op == :exp
        return simplify_once(UnaryOp(:exp, left.arg + right.arg))
    end

    # exp(a) / exp(b) = exp(a-b)
    if expr.op == :/ && left isa UnaryOp && left.op == :exp &&
       right isa UnaryOp && right.op == :exp
        return simplify_once(UnaryOp(:exp, left.arg - right.arg))
    end

    # Logarithm addition/subtraction
    # log(a) + log(b) = log(a*b)
    if expr.op == :+ && left isa UnaryOp && left.op == :log &&
       right isa UnaryOp && right.op == :log
        return simplify_once(UnaryOp(:log, left.arg * right.arg))
    end

    # log(a) - log(b) = log(a/b)
    if expr.op == :- && left isa UnaryOp && left.op == :log &&
       right isa UnaryOp && right.op == :log
        return simplify_once(UnaryOp(:log, left.arg / right.arg))
    end

    # Trigonometric identities
    # sin(x)^2 + cos(x)^2 = 1
    if expr.op == :+
        # Check if left is sin^2 and right is cos^2
        if left isa BinaryOp && left.op == :^ && left.right isa Const && left.right.value == 2 &&
           left.left isa UnaryOp && left.left.op == :sin &&
           right isa BinaryOp && right.op == :^ && right.right isa Const && right.right.value == 2 &&
           right.left isa UnaryOp && right.left.op == :cos &&
           left.left.arg == right.left.arg
            return Const(1)
        end
        # Check if left is cos^2 and right is sin^2
        if left isa BinaryOp && left.op == :^ && left.right isa Const && left.right.value == 2 &&
           left.left isa UnaryOp && left.left.op == :cos &&
           right isa BinaryOp && right.op == :^ && right.right isa Const && right.right.value == 2 &&
           right.left isa UnaryOp && right.left.op == :sin &&
           left.left.arg == right.left.arg
            return Const(1)
        end
    end

    # Try to combine like terms if it's an addition
    result = BinaryOp(expr.op, left, right)
    if expr.op == :+
        result = combine_like_terms(result)
    end

    return result
end

# Check if an expression matches the pattern a^2
function is_squared(expr::SymExpr)
    if expr isa BinaryOp && expr.op == :^
        if expr.right isa Const && expr.right.value == 2
            return true, expr.left
        end
    end
    return false, nothing
end

# Flatten multiplication expressions into a list of factors
function flatten_multiplication(expr::SymExpr)
    if expr isa BinaryOp && expr.op == :*
        return vcat(flatten_multiplication(expr.left), flatten_multiplication(expr.right))
    else
        return [expr]
    end
end

# Check if an expression matches the pattern 2*a*b
function is_double_product(expr::SymExpr, a::SymExpr, b::SymExpr)
    if expr isa BinaryOp && expr.op == :*
        # Flatten to get all factors
        factors = flatten_multiplication(expr)

        # Check if it contains 2, a, and b
        has_two = false
        remaining_factors = []

        for factor in factors
            if factor isa Const && factor.value == 2 && !has_two
                has_two = true
            else
                push!(remaining_factors, factor)
            end
        end

        if has_two && length(remaining_factors) == 2
            # Check if the remaining factors are a and b in any order
            if (remaining_factors[1] == a && remaining_factors[2] == b) ||
               (remaining_factors[1] == b && remaining_factors[2] == a)
                return true
            end
        end
    end
    return false
end

# Recognize perfect square pattern: a^2 + 2*a*b + b^2 = (a+b)^2
function recognize_perfect_square(expr::SymExpr)
    if !(expr isa BinaryOp && expr.op == :+)
        return nothing
    end

    # Flatten to get all terms
    terms = flatten_addition(expr)

    if length(terms) != 3
        return nothing
    end

    # Try all permutations to find a^2, 2*a*b, b^2
    for i in 1:3
        for j in 1:3
            for k in 1:3
                if i != j && j != k && i != k
                    term_a2 = terms[i]
                    term_2ab = terms[j]
                    term_b2 = terms[k]

                    is_a2, a = is_squared(term_a2)
                    is_b2, b = is_squared(term_b2)

                    if is_a2 && is_b2 && a !== nothing && b !== nothing
                        if is_double_product(term_2ab, a, b)
                            # Found pattern: a^2 + 2*a*b + b^2 = (a+b)^2
                            return (a + b) ^ Const(2)
                        end
                    end
                end
            end
        end
    end

    return nothing
end

# Helper function to check if two expressions are "like terms" (same structure)
function are_like_terms(e1::SymExpr, e2::SymExpr)
    if e1 isa Sym && e2 isa Sym
        return e1.name == e2.name
    elseif e1 isa BinaryOp && e2 isa BinaryOp
        return e1.op == e2.op && are_like_terms(e1.left, e2.left) && are_like_terms(e1.right, e2.right)
    elseif e1 isa UnaryOp && e2 isa UnaryOp
        return e1.op == e2.op && are_like_terms(e1.arg, e2.arg)
    else
        return false
    end
end

# Flatten addition expressions into a list of terms
function flatten_addition(expr::SymExpr)
    if expr isa BinaryOp && expr.op == :+
        return vcat(flatten_addition(expr.left), flatten_addition(expr.right))
    else
        return [expr]
    end
end

# Get the coefficient and term from an expression
# Returns (coefficient, term) where coefficient defaults to 1
function get_coeff_and_term(expr::SymExpr)
    if expr isa BinaryOp && expr.op == :* && expr.left isa Const
        return (expr.left.value, expr.right)
    else
        return (1, expr)
    end
end

# Combine like terms in addition: a*x + b*x = (a+b)*x
function combine_like_terms(expr::BinaryOp)
    if expr.op != :+
        return expr
    end

    # First, check if this is a perfect square pattern
    perfect_square = recognize_perfect_square(expr)
    if perfect_square !== nothing
        return perfect_square
    end

    # Flatten the addition into individual terms
    terms = flatten_addition(expr)

    # Group terms by their structure (like terms together)
    term_groups = Dict()
    for term in terms
        coeff, base_term = get_coeff_and_term(term)
        base_key = string(base_term)  # Use string representation as key

        if !haskey(term_groups, base_key)
            term_groups[base_key] = (base_term, 0)
        end

        existing_term, existing_coeff = term_groups[base_key]
        term_groups[base_key] = (existing_term, existing_coeff + coeff)
    end

    # Reconstruct expression with combined like terms
    combined_terms = []
    for (key, (base_term, total_coeff)) in term_groups
        if total_coeff == 0
            continue  # Skip terms with zero coefficient
        elseif total_coeff == 1
            push!(combined_terms, base_term)
        else
            push!(combined_terms, Const(total_coeff) * base_term)
        end
    end

    # Rebuild the addition expression
    if isempty(combined_terms)
        return Const(0)
    elseif length(combined_terms) == 1
        return combined_terms[1]
    else
        # Fold left to build the expression
        result = combined_terms[1]
        for i in 2:length(combined_terms)
            result = result + combined_terms[i]
        end
        return result
    end
end

# Count the number of operations in an expression
# This is used to measure complexity (similar to sympy's count_ops)
function count_ops(expr::SymExpr)
    if expr isa Sym || expr isa Const
        return 0
    elseif expr isa UnaryOp
        return 1 + count_ops(expr.arg)
    elseif expr isa BinaryOp
        return 1 + count_ops(expr.left) + count_ops(expr.right)
    else
        return 0
    end
end

# Select the expression with fewer operations
function shorter(exprs::SymExpr...)
    if length(exprs) == 0
        throw(ArgumentError("Need at least one expression"))
    end
    return exprs[argmin([count_ops(e) for e in exprs])]
end

# Convenience functions to convert numbers to Const
simplify(x::Number) = Const(x)
Simplify(x::Number) = Const(x)

"""
    Simplify(expr::SymExpr; ratio=1.7, max_iterations=100)

Simplify a symbolic expression using various simplification strategies.

The simplification process recursively applies simplification rules until
a fixed point is reached or the maximum number of iterations is exceeded.

# Arguments
- `expr::SymExpr`: The expression to simplify
- `ratio::Float64`: Maximum ratio of result complexity to input complexity (default: 1.7)
- `max_iterations::Int`: Maximum number of simplification iterations (default: 100)

# Returns
- `SymExpr`: The simplified expression

# Examples
```julia
x = Sym(:x)
expr = sin(asin(x))
simplified = Simplify(expr)  # Returns x

expr2 = log(exp(x))
simplified2 = Simplify(expr2)  # Returns x

expr3 = sin(x)^2 + cos(x)^2
simplified3 = Simplify(expr3)  # Returns Const(1)
```

Inspired by SymPy's simplify function, this implementation tries multiple
simplification strategies and selects the result with the fewest operations,
while ensuring the result is not too much more complex than the input.
"""
function Simplify(expr::SymExpr; ratio::Float64=1.7, max_iterations::Int=100)
    original_expr = expr
    original_ops = count_ops(original_expr)

    # Recursively simplify until reaching a fixed point
    prev = nothing
    iterations = 0

    while prev !== expr && iterations < max_iterations
        prev = expr
        expr = simplify_once(expr)
        iterations += 1
    end

    # Check if the simplified expression is acceptable based on ratio
    if ratio != Inf && original_ops > 0
        simplified_ops = count_ops(expr)
        if simplified_ops / original_ops > ratio
            return original_expr
        end
    end

    expr
end
