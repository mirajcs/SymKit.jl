using SymKit
using Test


@testset "Simple Operations" begin
    x, y = @sym x y

    expr = x + y
    @test expr isa BinaryOp
    @test expr.op == :+
end

@testset "Simplification" begin
    @sym x y

    # Test constant folding
    @test Simplify(Const(2) + Const(3)) == Const(5)
    @test Simplify(Const(5) * Const(2)) == Const(10)
    @test Simplify(Const(2) ^ Const(3)) == Const(8)

    # Test identity rules
    @test Simplify(x + Const(0)) == x
    @test Simplify(Const(0) + x) == x
    @test Simplify(x * Const(1)) == x
    @test Simplify(Const(1) * x) == x
    @test Simplify(x ^ Const(0)) == Const(1)
    @test Simplify(x ^ Const(1)) == x
    @test Simplify(x - Const(0)) == x
    @test Simplify(x / Const(1)) == x

    # Test complex expressions
    @test Simplify((Const(2) + Const(3)) * x) == (Const(5) * x)
    @test Simplify(x * Const(0)) == Const(0)

    # Test double negation
    @test Simplify(-(-x)) == x
end

@testset "Differentiation" begin
    @sym x y

    # Test constant differentiation
    @test Derivative(5, x) == Const(0)
    @test Derivative(0, x) == Const(0)

    # Test variable differentiation
    @test Derivative(x, x) == Const(1)
    @test Derivative(y, x) == Const(0)
    @test Derivative(x, y) == Const(0)

    # Test addition rule
    @test Derivative(x + y, x) == Const(1) + Const(0)
    @test Derivative(x + x, x) == Const(1) + Const(1)

    # Test subtraction rule
    @test Derivative(x - y, x) == Const(1) - Const(0)
    @test Derivative(x - x, x) == Const(1) - Const(1)

    # Test product rule: d/dx(x*y) = 1*y + x*0
    @test Derivative(x * y, x) == (Const(1) * y + x * Const(0))
    @test Derivative(x * x, x) == (Const(1) * x + x * Const(1))

    # Test power rule: d/dx(x^2) = 2*x^(2-1)*1 = 2*x^1*1
    expr_power = x ^ Const(2)
    result_power = Derivative(expr_power, x)
    @test result_power == (Const(2) * (x ^ (Const(2) - Const(1))) * Const(1))

    # Test negation in differentiation
    @test Derivative(-x, x) == -(Const(1))
    @test Derivative(-(x + y), x) == -(Const(1) + Const(0))
end

@testset "Arithmetic Operations" begin
    @sym x y z

    # Test expression creation with different operators
    @test (x + y) isa BinaryOp
    @test (x - y) isa BinaryOp
    @test (x * y) isa BinaryOp
    @test (x / y) isa BinaryOp
    @test (x ^ y) isa BinaryOp
    @test (-x) isa UnaryOp

    # Test operator symbols
    @test (x + y).op == :+
    @test (x - y).op == :-
    @test (x * y).op == :*
    @test (x / y).op == :/
    @test (x ^ y).op == :^
    @test (-x).op == :-

    # Test mixed operations
    expr1 = x + y * z
    @test expr1 isa BinaryOp
    @test expr1.op == :+
    @test expr1.left == x
    @test expr1.right isa BinaryOp
    @test expr1.right.op == :*
end

@testset "Complex Expressions" begin
    @sym x y

    # Test nested operations
    expr1 = (x + y) * (x - y)
    @test expr1 isa BinaryOp
    @test expr1.op == :*

    # Test simplification of complex nested expressions
    expr2 = Simplify((x + Const(0)) * (Const(1) * x))
    @test expr2 == (x * x)

    # Test differentiation of complex expressions
    expr3 = x ^ Const(3)
    deriv = Derivative(expr3, x)
    @test deriv isa BinaryOp || deriv isa UnaryOp || deriv isa Const || deriv isa Sym

    # Test negation of complex expressions
    expr4 = -((x + y) * x)
    @test expr4 isa UnaryOp
    @test expr4.arg isa BinaryOp
end

@testset "Distributive Property" begin
    @sym x y

    # Test distributive rule: a*(b+c) = a*b + a*c
    @test Simplify(Const(2) * (x + Const(3))) == ((Const(2) * x) + Const(6))
    @test Simplify(Const(5) * (x + y)) == ((Const(5) * x) + (Const(5) * y))

    # Test distributive rule: (a+b)*c = a*c + b*c (order may vary due to flattening)
    result1 = Simplify((x + Const(2)) * Const(3))
    @test result1 == (Const(6) + (x * Const(3))) || result1 == ((x * Const(3)) + Const(6))

    result2 = Simplify((x + y) * Const(2))
    @test result2 isa BinaryOp  # Just check it's a valid expression

    # Test complex expressions with distributive property (now fully simplified with like terms combined)
    expr = Simplify(x + Const(2) * (x + Const(2)))
    @test expr == (Const(4) + (Const(3) * x)) || expr == ((Const(3) * x) + Const(4))
end

@testset "Like Terms Combination" begin
    @sym x y

    # Test combining identical terms
    @test Simplify(x + x) == (Const(2) * x)
    @test Simplify(y + y) == (Const(2) * y)

    # Test combining like terms with constants
    @test Simplify(Const(2) * x + Const(3) * x) == (Const(5) * x)
    @test Simplify(Const(1) * x + Const(2) * x) == (Const(3) * x)

    # Test term + coefficient*term
    @test Simplify(x + Const(2) * x) == (Const(3) * x)
    @test Simplify(Const(2) * x + x) == (Const(3) * x)

    # Test multiple like term combinations
    expr = Simplify(x + x + x)
    # This will be ((2*x) + x) which should further simplify to (3*x)
    @test expr == (Const(3) * x)
end

@testset "Perfect Square Recognition" begin
    @sym x y z

    # Test perfect square: x^2 + 2*x*y + y^2 = (x+y)^2
    @test Simplify((x ^ Const(2)) + Const(2) * x * y + (y ^ Const(2))) == ((x + y) ^ Const(2))

    # Test perfect square with different variable
    @test Simplify((y ^ Const(2)) + Const(2) * x * y + (x ^ Const(2))) == ((x + y) ^ Const(2))

    # Test perfect square with three variables
    @test Simplify((x ^ Const(2)) + Const(2) * x * z + (z ^ Const(2))) == ((x + z) ^ Const(2))

    # Test that non-perfect squares aren't simplified
    result = Simplify((x ^ Const(2)) + x * y + (y ^ Const(2)))
    @test !(result isa BinaryOp && result.op == :^ && result.right == Const(2))
end
