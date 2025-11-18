# Internal helper function - applies one simplification rule
function simplify_once(expr::SymExpr)
    # Base cases: Sym and Const are already simplified
    expr isa Sym && return expr
    expr isa Const && return expr

    # Simplify UnaryOp
    expr isa UnaryOp && return simplify_unary(expr)

    # Simplify BinaryOp
    expr isa BinaryOp && return simplify_binary(expr)

    return expr
end

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

# Convenience function to convert numbers to Const
simplify(x::Number) = Const(x)

function Simplify(expr::SymExpr)
    # Recursively simplify until reaching a fixed point
    prev = nothing
    max_iterations = 100  # Prevent infinite loops
    iterations = 0

    while prev !== expr && iterations < max_iterations
        prev = expr
        expr = simplify_once(expr)
        iterations += 1
    end

    expr
end
