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

    # Test addition rule (simplified)
    @test Derivative(x + y, x) == Const(1)
    @test Derivative(x + x, x) == Const(2)  # x+x simplifies to 2x, d/dx(2x) = 2

    # Test subtraction rule (simplified)
    @test Derivative(x - y, x) == Const(1)
    @test Derivative(x - x, x) == Const(0)

    # Test product rule: d/dx(x*y) simplified = y
    @test Derivative(x * y, x) == y
    # d/dx(x*x) simplified = 2*x
    @test Derivative(x * x, x) == Const(2) * x

    # Test power rule: d/dx(x^2) simplified = 2*x
    @test Derivative(x ^ Const(2), x) == Const(2) * x
    # d/dx(x^3) simplified = 3*x^2
    @test Derivative(x ^ Const(3), x) == Const(3) * (x ^ Const(2))

    # Test negation in differentiation
    @test Derivative(-x, x) == -(Const(1))
    @test Derivative(-(x + y), x) == -(Const(1))
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

@testset "Square Root" begin
    @sym x

    # Test sqrt creation with symbolic variable
    @test sqrt(x) isa UnaryOp
    @test sqrt(x).op == :sqrt

    # Test sqrt with Const
    @test sqrt(Const(4)) isa UnaryOp
    @test sqrt(Const(4)).op == :sqrt

    # Test constant folding: sqrt(4) = 2
    @test Simplify(sqrt(Const(4))).value == 2.0
    @test Simplify(sqrt(Const(9))).value == 3.0
    @test Simplify(sqrt(Const(16))).value == 4.0

    # Test sqrt with zero
    @test Simplify(sqrt(Const(0))).value == 0.0

    # Test sqrt with one
    @test Simplify(sqrt(Const(1))).value == 1.0

    # Test differentiation: d/dx(√x) = 1/(2√x)
    deriv = Derivative(sqrt(x), x)
    @test deriv isa BinaryOp  # Should be 1 / (2*sqrt(x))
    @test deriv.op == :/

    # Test differentiation of sqrt with expression: d/dx(√(x+1)) = 1/(2√(x+1))
    deriv2 = Derivative(sqrt(x + Const(1)), x)
    @test deriv2 isa BinaryOp
    @test deriv2.op == :/
end

@testset "Absolute Value" begin
    @sym x

    # Test abs creation
    @test abs(x) isa UnaryOp
    @test abs(x).op == :abs

    # Test abs with Const
    @test abs(Const(-5)) isa UnaryOp
    @test abs(Const(-5)).op == :abs

    # Test constant folding: abs(-5) = 5
    @test Simplify(abs(Const(-5))).value == 5.0
    @test Simplify(abs(Const(3))).value == 3.0
    @test Simplify(abs(Const(0))).value == 0.0

    # Test abs(-x) = abs(x)
    result = Simplify(abs(-x))
    @test result isa UnaryOp
    @test result.op == :abs
    @test result.arg == x

    # Test sqrt(x^2) = abs(x)
    result = Simplify(sqrt(x ^ Const(2)))
    @test result isa UnaryOp
    @test result.op == :abs
    @test result.arg == x

    # Test sqrt with constant squared: sqrt(4^2) fully simplifies to 4
    result = Simplify(sqrt(Const(4) ^ Const(2)))
    @test result.value == 4.0  # Fully simplified

    # Test differentiation: d/dx(|x|) = x/|x|
    deriv = Derivative(abs(x), x)
    @test deriv isa BinaryOp
    @test deriv.op == :/
end

@testset "Evaluate and Limits" begin
    @sym x y

    # Test basic evaluation
    @test evaluate(x, x, 5) == Const(5)
    @test evaluate(Const(3), x, 5) == Const(3)

    # Test evaluation with expressions
    expr = x + Const(2)
    result = evaluate(expr, x, 3)
    @test result == Const(5)

    # Test evaluation with polynomial
    expr = x^2 + 3*x + 2
    result = evaluate(expr, x, 2)
    @test result == Const(12)  # 4 + 6 + 2

    # Test has_variable
    @test has_variable(x, x) == true
    @test has_variable(y, x) == false
    @test has_variable(x + y, x) == true
    @test has_variable(Const(5), x) == false

    # Test get_denominator
    expr = 1 / x
    @test get_denominator(expr) == x

    expr = (x + 1) / (x - 1)
    denom = get_denominator(expr)
    @test denom.op == :-
    @test denom.left == x
    @test denom.right == Const(1)

    # Test division by constant zero detection
    @test_throws ErrorException Simplify(Const(5) / Const(0))

    # Test limit function with simple expression
    expr = 1 / x
    left_lim = limit(expr, x, 0; direction=:left)
    right_lim = limit(expr, x, 0; direction=:right)

    # Left limit should be negative infinity, right limit positive infinity
    @test left_lim == Symbol("-inf")
    @test right_lim == :inf

    # Test both direction limit
    both_lims = limit(expr, x, 0; direction=:both)
    @test both_lims == (Symbol("-inf"), :inf)

    # Test check_division_limits
    analysis = check_division_limits(expr, x)
    @test analysis[:has_singularity] == true
    @test length(analysis[:singularities]) > 0

    # Test describe_division_behavior
    desc = describe_division_behavior(expr, x)
    @test typeof(desc) == String
    @test contains(desc, "Discontinuous") || contains(desc, "x=0")

    # Test with removable singularity: (x-1)/(x-1) = 1
    expr = (x - 1) / (x - 1)
    analysis = check_division_limits(expr, x)
    # This should still report singularity since denominator is 0 at x=1
    @test analysis[:has_singularity] == true

    # Test find_singularities
    expr = 1 / (x - 2)
    sings = find_singularities(expr, x)
    @test length(sings) > 0  # Should find the division

    # Test with complex expression
    expr = (x + 1) / (x^2 - 1)
    sings = find_singularities(expr, x)
    @test length(sings) > 0

end
