# Basic differentiation (with automatic simplification)
Derivative(expr::SymExpr, var::Sym) = Simplify(diff_impl(expr, var))
Derivative(expr::SymExpr, var::Symbol) = Derivative(expr, Sym(var))

# Convenience methods for plain numbers
Derivative(expr::Number, var::Sym) = Derivative(Const(expr), var)
Derivative(expr::Number, var::Symbol) = Derivative(Const(expr), var)

diff_impl(c::Const, var::Sym) = Const(0)
diff_impl(s::Sym, var::Sym) = s.name == var.name ? Const(1) : Const(0)

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

function diff_impl(u::UnaryOp, var::Sym)
    if u.op == :-
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
