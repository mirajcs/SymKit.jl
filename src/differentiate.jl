"""
    Derivative(expr::SymExpr, var::Sym)

Compute the symbolic derivative of an expression with respect to a variable.

The function recursively applies differentiation rules and automatically simplifies
the result. Supports basic operations (+, -, *, /, ^) and unary operations (-, sqrt, abs).

# Arguments:
- `expr::SymExpr`: The expression to differentiate
- `var::Sym` or `var::Symbol`: The variable to differentiate with respect to

# Returns:
- A simplified SymExpr representing the derivative

# Differentiation Rules:
- Constant rule: d/dx(c) = 0
- Variable rule: d/dx(x) = 1, d/dx(y) = 0 (if differentiating w.r.t. x)
- Sum rule: d/dx(f + g) = f' + g'
- Difference rule: d/dx(f - g) = f' - g'
- Product rule: d/dx(f*g) = f'*g + f*g'
- Quotient rule: d/dx(f/g) = (f'*g - f*g') / g²
- Power rule: d/dx(f^n) = n*f^(n-1)*f' (for constant exponents)
- Chain rules for unary operations:
  - d/dx(√f) = f' / (2√f)
  - d/dx(|f|) = f' * sgn(f)
  - d/dx(-f) = -f'

# Examples:
    x = Sym(:x)

    # Simple polynomial
    expr = x^2 + 3*x + 2
    result = Derivative(expr, x)  # Returns BinaryOp(:+, BinaryOp(:+, BinaryOp(:*, ...), 3), 0)
    # After simplification: 2*x + 3

    # Quotient rule
    expr = 1 / x
    result = Derivative(expr, x)  # Returns -1/x²

    # Product rule
    expr = x^2 * (x + 1)
    result = Derivative(expr, x)  # Returns 3*x² + 2*x
"""
Derivative(expr::SymExpr, var::Sym) = Simplify(diff_impl(expr, var))

"""
    Derivative(expr::SymExpr, var::Symbol)

Convenience method that accepts Symbol instead of Sym for the variable.
"""
Derivative(expr::SymExpr, var::Symbol) = Derivative(expr, Sym(var))

"""
    Derivative(expr::Number, var::Sym)
    Derivative(expr::Number, var::Symbol)

Convenience methods that accept plain numbers and automatically wrap them in Const.
The derivative of any constant is zero.
"""
Derivative(expr::Number, var::Sym) = Derivative(Const(expr), var)
Derivative(expr::Number, var::Symbol) = Derivative(Const(expr), var)

# Internal differentiation implementation
# Base cases for Const and Sym
diff_impl(c::Const, var::Sym) = Const(0)
diff_impl(s::Sym, var::Sym) = s.name == var.name ? Const(1) : Const(0)

# BinaryOp differentiation - applies product rule, quotient rule, power rule, etc.
function diff_impl(b::BinaryOp, var::Sym)
    if b.op == :+
        diff_impl(b.left, var) + diff_impl(b.right, var)
    elseif b.op == :-
        diff_impl(b.left, var) - diff_impl(b.right, var)
    elseif b.op == :*
        # Product rule: d/dx(f*g) = f'*g + f*g'
        diff_impl(b.left, var) * b.right + b.left * diff_impl(b.right, var)
    elseif b.op == :/
        # Quotient rule: d/dx(f/g) = (f'*g - f*g')/g^2
        (diff_impl(b.left, var) * b.right - b.left * diff_impl(b.right, var)) / (b.right ^ 2)
    elseif b.op == :^
        # Power rule (simplified): d/dx(f^n) = n*f^(n-1)*f' (assuming n is constant)
        b.right * (b.left ^ (b.right - 1)) * diff_impl(b.left, var)
    else
        error("Unknown binary operator: $(b.op)")
    end
end

# UnaryOp differentiation - applies chain rule for unary operations
function diff_impl(u::UnaryOp, var::Sym)
    if u.op == :-
        # d/dx(-f) = -f'
        -diff_impl(u.arg, var)
    elseif u.op == :sqrt
        # d/dx(√f) = f' / (2√f)
        diff_impl(u.arg, var) / (Const(2) * UnaryOp(:sqrt, u.arg))
    elseif u.op == :abs
        # d/dx(|f|) = f' * f / |f| = f' * sgn(f)
        diff_impl(u.arg, var) * u.arg / UnaryOp(:abs, u.arg)
    else
        error("Unknown unary operator: $(u.op)")
    end
end
