# Evaluate expressions by substituting variable values

"""
    Evaluate(expr::SymExpr, var::Sym, value::Number)

Substitute a variable with a numeric value in an expression.
Returns the result as a SymExpr (which may be a Const if fully evaluated).

Example:
    x = Sym(:x)
    expr = x^2 + 3*x + 2
    result = Evaluate(expr, x, 2)  # Returns Const(12)
"""
# Multiple dispatch implementation for different expression types

# Symbol: check if it matches the variable to substitute
Evaluate(expr::Sym, var::Sym, value::Number) =
    expr.name == var.name ? Const(value) : expr

# Constant: unchanged
Evaluate(expr::Const, var::Sym, value::Number) = expr

# UnaryOp: recursively evaluate argument
function Evaluate(expr::UnaryOp, var::Sym, value::Number)
    arg_eval = Evaluate(expr.arg, var, value)
    return simplify_once(UnaryOp(expr.op, arg_eval))
end

# BinaryOp: recursively evaluate both operands
function Evaluate(expr::BinaryOp, var::Sym, value::Number)
    left_eval = Evaluate(expr.left, var, value)
    right_eval = Evaluate(expr.right, var, value)
    return simplify_once(BinaryOp(expr.op, left_eval, right_eval))
end

"""
    hasVariable(expr::SymExpr, var::Sym)

Check if an expression contains a specific variable.

Example:
    x = Sym(:x)
    y = Sym(:y)
    expr = x^2 + 3*y
    hasVariable(expr, x)  # Returns true
    hasVariable(expr, y)  # Returns true
    hasVariable(expr, Sym(:z))  # Returns false
"""
# Multiple dispatch implementation for different expression types

# Symbol: check if names match
hasVariable(expr::Sym, var::Sym) = expr.name == var.name

# Constant: never contains variables
hasVariable(expr::Const, var::Sym) = false

# UnaryOp: check the argument
hasVariable(expr::UnaryOp, var::Sym) = hasVariable(expr.arg, var)

# BinaryOp: check both operands
hasVariable(expr::BinaryOp, var::Sym) =
    hasVariable(expr.left, var) || hasVariable(expr.right, var)

"""
    Denominator(expr::SymExpr)

Extract the denominator from a division expression.
If expr is not a division, returns nothing.

Example:
    x = Sym(:x)
    expr = (x+1) / (x-1)
    denom = Denominator(expr)  # Returns BinaryOp(:-, Sym(:x), Const(1))
"""
function Denominator(expr::SymExpr)
    if expr isa BinaryOp && expr.op == :/
        return expr.right
    else
        return nothing
    end
end

"""
    Singularities(expr::SymExpr, _var::Sym)

Find potential singularities (points where denominator = 0) in an expression.
For polynomial denominators, tries to find roots.

Returns a vector of potential singularity points (as Numbers or symbols).
For complex expressions, may return an empty vector or approximate solutions.

Example:
    x = Sym(:x)
    expr = 1 / (x - 2)
    singularities = Singularities(expr, x)  # Returns [2] or similar
"""
function Singularities(expr::SymExpr, _var::Sym)
    singularities = []

    # Recursively search for division operations
    function find_divs(e::SymExpr)
        if e isa BinaryOp
            if e.op == :/
                # Found a division - the right side is the denominator
                # For now, we'll check if it can be evaluated to zero
                push!(singularities, e.right)
            end
            find_divs(e.left)
            find_divs(e.right)
        elseif e isa UnaryOp
            find_divs(e.arg)
        end
    end

    find_divs(expr)
    return singularities
end
