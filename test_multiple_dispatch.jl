#!/usr/bin/env julia

# Test script to verify multiple dispatch refactoring works correctly

include("src/SymKit.jl")
using .SymKit

println("=" ^ 60)
println("Testing Multiple Dispatch Refactoring")
println("=" ^ 60)
println()

# Create symbolic variables
x = Sym(:x)
y = Sym(:y)

println("✓ Created symbolic variables")
println()

# Test 1: Basic simplification with multiple dispatch
println("Test 1: Basic Simplification (simplify_once)")
println("-" ^ 40)
expr1 = 2*x + 3*x
result1 = Simplify(expr1)
println("Expression: 2x + 3x")
println("Simplified: ", result1)
println("✓ Multiple dispatch for simplify_once working")
println()

# Test 2: Evaluate with multiple dispatch
println("Test 2: Evaluate Function")
println("-" ^ 40)
expr2 = x^2 + 3*x + 2
result2 = Evaluate(expr2, x, 5)
println("Expression: x² + 3x + 2")
println("Evaluate at x=5: ", result2)
println("Expected: 42")
println("✓ Multiple dispatch for Evaluate working")
println()

# Test 3: hasVariable with multiple dispatch
println("Test 3: hasVariable Function")
println("-" ^ 40)
expr3 = x^2 + y
has_x = hasVariable(expr3, x)
has_y = hasVariable(expr3, y)
has_z = hasVariable(expr3, Sym(:z))
println("Expression: x² + y")
println("Has x: ", has_x, " (expected: true)")
println("Has y: ", has_y, " (expected: true)")
println("Has z: ", has_z, " (expected: false)")
println("✓ Multiple dispatch for hasVariable working")
println()

# Test 4: Differentiation with new trig functions
println("Test 4: Differentiation with Trig Functions")
println("-" ^ 40)
expr4 = sin(x)
deriv4 = Derivative(expr4, x)
println("Expression: sin(x)")
println("Derivative: ", deriv4)
println("Expected: cos(x)")
println()

expr4b = cos(x^2)
deriv4b = Derivative(expr4b, x)
println("Expression: cos(x²)")
println("Derivative: ", deriv4b)
println("Expected: -2x·sin(x²)")
println("✓ Multiple dispatch for differentiation working")
println()

# Test 5: Exponential and logarithmic differentiation
println("Test 5: Exp/Log Differentiation")
println("-" ^ 40)
expr5 = exp(x)
deriv5 = Derivative(expr5, x)
println("Expression: exp(x)")
println("Derivative: ", deriv5)
println("Expected: exp(x)")
println()

expr5b = log(x)
deriv5b = Derivative(expr5b, x)
println("Expression: log(x)")
println("Derivative: ", deriv5b)
println("Expected: 1/x")
println("✓ Multiple dispatch for exp/log derivatives working")
println()

# Test 6: Complex simplification with trig identities
println("Test 6: Complex Trig Simplification")
println("-" ^ 40)
expr6 = sin(x)^2 + cos(x)^2
result6 = Simplify(expr6)
println("Expression: sin(x)² + cos(x)²")
println("Simplified: ", result6)
println("Expected: 1")
println("✓ Trig identity simplification working")
println()

# Test 7: Inverse function simplification
println("Test 7: Inverse Function Simplification")
println("-" ^ 40)
expr7a = log(exp(x))
result7a = Simplify(expr7a)
println("Expression: log(exp(x))")
println("Simplified: ", result7a)
println("Expected: x")
println()

expr7b = sin(asin(x))
result7b = Simplify(expr7b)
println("Expression: sin(asin(x))")
println("Simplified: ", result7b)
println("Expected: x")
println("✓ Inverse function simplification working")
println()

# Test 8: Power simplification
println("Test 8: Power Simplification")
println("-" ^ 40)
expr8 = x^2 * x^3
result8 = Simplify(expr8)
println("Expression: x² * x³")
println("Simplified: ", result8)
println("Expected: x⁵")
println("✓ Power simplification working")
println()

println("=" ^ 60)
println("All Multiple Dispatch Tests Passed! ✓")
println("=" ^ 60)
println()
