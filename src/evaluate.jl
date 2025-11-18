# Evaluate expressions by substituting variable values

"""
    evaluate(expr::SymExpr, var::Sym, value::Number)

Substitute a variable with a numeric value in an expression.
Returns the result as a SymExpr (which may be a Const if fully evaluated).

Example:
    x = Sym(:x)
    expr = x^2 + 3*x + 2
    result = evaluate(expr, x, 2)  # Returns Const(12)
"""
function Evaluate(expr::SymExpr, var::Sym, value::Number)
    if expr isa Sym
        return expr.name == var.name ? Const(value) : expr
    elseif expr isa Const
        return expr
    elseif expr isa UnaryOp
        arg_eval = Evaluate(expr.arg, var, value)
        return simplify_once(UnaryOp(expr.op, arg_eval))
    elseif expr isa BinaryOp
        left_eval = Evaluate(expr.left, var, value)
        right_eval = Evaluate(expr.right, var, value)
        return simplify_once(BinaryOp(expr.op, left_eval, right_eval))
    else
        return expr
    end
end

"""
    has_variable(expr::SymExpr, var::Sym)

Check if an expression contains a specific variable.

Example:
    x = Sym(:x)
    y = Sym(:y)
    expr = x^2 + 3*y
    has_variable(expr, x)  # Returns true
    has_variable(expr, y)  # Returns true
    has_variable(expr, Sym(:z))  # Returns false
"""
function hasVariable(expr::SymExpr, var::Sym)
    if expr isa Sym
        return expr.name == var.name
    elseif expr isa Const
        return false
    elseif expr isa UnaryOp
        return hasVariable(expr.arg, var)
    elseif expr isa BinaryOp
        return hasVariable(expr.left, var) || hasVariable(expr.right, var)
    else
        return false
    end
end

"""
    get_denominator(expr::SymExpr)

Extract the denominator from a division expression.
If expr is not a division, returns nothing.

Example:
    x = Sym(:x)
    expr = (x+1) / (x-1)
    denom = get_denominator(expr)  # Returns BinaryOp(:-, Sym(:x), Const(1))
"""
function Denominator(expr::SymExpr)
    if expr isa BinaryOp && expr.op == :/
        return expr.right
    else
        return nothing
    end
end

"""
    find_singularities(expr::SymExpr, _var::Sym)

Find potential singularities (points where denominator = 0) in an expression.
For polynomial denominators, tries to find roots.

Returns a vector of potential singularity points (as Numbers or symbols).
For complex expressions, may return an empty vector or approximate solutions.

Example:
    x = Sym(:x)
    expr = 1 / (x - 2)
    singularities = find_singularities(expr, x)  # Returns [2] or similar
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
