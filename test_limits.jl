push!(LOAD_PATH, "/Users/mirajcs/git/SymKit/SymKit/src")

using SymKit
using Test

println("Testing SymKit Limits and Evaluation functionality...")

@testset "Evaluate and Limits" begin
    @sym x y

    # Test basic evaluation
    @test evaluate(x, x, 5) == Const(5)
    @test evaluate(Const(3), x, 5) == Const(3)
    println("✓ Basic evaluation tests passed")

    # Test evaluation with expressions
    expr = x + Const(2)
    result = evaluate(expr, x, 3)
    @test result == Const(5)
    println("✓ Expression evaluation tests passed")

    # Test evaluation with polynomial
    expr = x^2 + 3*x + 2
    result = evaluate(expr, x, 2)
    @test result == Const(12)  # 4 + 6 + 2
    println("✓ Polynomial evaluation tests passed")

    # Test has_variable
    @test has_variable(x, x) == true
    @test has_variable(y, x) == false
    @test has_variable(x + y, x) == true
    @test has_variable(Const(5), x) == false
    println("✓ has_variable tests passed")

    # Test get_denominator
    expr = 1 / x
    @test get_denominator(expr) == x
    println("✓ Basic denominator extraction passed")

    expr = (x + 1) / (x - 1)
    denom = get_denominator(expr)
    @test denom.op == :-
    @test denom.left == x
    @test denom.right == Const(1)
    println("✓ Complex denominator extraction passed")

    # Test division by constant zero produces Inf
    result = Simplify(Const(5) / Const(0))
    @test isinf(result.value)
    println("✓ Division by zero detection passed (produces Inf)")

    # Test limit function with simple expression
    expr = 1 / x
    left_lim = limit(expr, x, 0; direction=:left)
    right_lim = limit(expr, x, 0; direction=:right)

    # Left limit should be negative infinity, right limit positive infinity
    @test left_lim == Symbol("-inf")
    @test right_lim == :inf
    println("✓ Left/right limit detection passed")

    # Test both direction limit
    both_lims = limit(expr, x, 0; direction=:both)
    @test both_lims == (Symbol("-inf"), :inf)
    println("✓ Bi-directional limit passed")

    # Test check_division_limits
    analysis = check_division_limits(expr, x)
    @test analysis[:has_singularity] == true
    @test length(analysis[:singularities]) > 0
    println("✓ Division limits analysis passed")

    # Test describe_division_behavior
    desc = describe_division_behavior(expr, x)
    @test typeof(desc) == String
    @test occursin("Discontinuous", desc) || occursin("x=0", desc)
    println("✓ Division behavior description passed")

    # Test with removable singularity: (x-1)/(x-1) = 1
    expr = (x - 1) / (x - 1)
    analysis = check_division_limits(expr, x)
    # This should still report singularity since denominator is 0 at x=1
    @test analysis[:has_singularity] == true
    println("✓ Removable singularity detection passed")

    # Test find_singularities
    expr = 1 / (x - 2)
    sings = find_singularities(expr, x)
    @test length(sings) > 0  # Should find the division
    println("✓ Singularity finding passed")

    # Test with complex expression
    expr = (x + 1) / (x^2 - 1)
    sings = find_singularities(expr, x)
    @test length(sings) > 0
    println("✓ Complex expression singularities found")

end

println("\nAll tests passed! ✓")
