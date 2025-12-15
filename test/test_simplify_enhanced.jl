#!/usr/bin/env julia

# Test script for enhanced Simplify command
# This demonstrates the new simplification capabilities inspired by SymPy

using Pkg
Pkg.activate("..")

include("../src/SymKit.jl")
using .SymKit

println("=" ^ 60)
println("Testing Enhanced Simplify Command")
println("Inspired by SymPy's simplify function")
println("=" ^ 60)
println()

# Create a symbolic variable
x = Sym(:x)
y = Sym(:y)

# Test 1: Trigonometric identities
println("Test 1: Trigonometric Identities")
println("-" ^ 40)
expr1 = sin(x)^2 + cos(x)^2
println("Expression: sin(x)² + cos(x)²")
println("Simplified: ", Simplify(expr1))
println("Expected: 1")
println()

# Test 2: Inverse trigonometric functions
println("Test 2: Inverse Trigonometric Functions")
println("-" ^ 40)
expr2 = sin(asin(x))
println("Expression: sin(asin(x))")
println("Simplified: ", Simplify(expr2))
println("Expected: x")
println()

expr2b = asin(sin(x))
println("Expression: asin(sin(x))")
println("Simplified: ", Simplify(expr2b))
println("Expected: x")
println()

# Test 3: Exponential and logarithmic identities
println("Test 3: Exponential and Logarithmic Identities")
println("-" ^ 40)
expr3 = log(exp(x))
println("Expression: log(exp(x))")
println("Simplified: ", Simplify(expr3))
println("Expected: x")
println()

expr3b = exp(log(x))
println("Expression: exp(log(x))")
println("Simplified: ", Simplify(expr3b))
println("Expected: x")
println()

# Test 4: Logarithm rules
println("Test 4: Logarithm Rules")
println("-" ^ 40)
expr4 = log(x) + log(y)
println("Expression: log(x) + log(y)")
println("Simplified: ", Simplify(expr4))
println("Expected: log(xy)")
println()

expr4b = log(x) - log(y)
println("Expression: log(x) - log(y)")
println("Simplified: ", Simplify(expr4b))
println("Expected: log(x/y)")
println()

# Test 5: Power simplification rules
println("Test 5: Power Simplification Rules")
println("-" ^ 40)
expr5 = log(x^2)
println("Expression: log(x²)")
println("Simplified: ", Simplify(expr5))
println("Expected: 2log(x)")
println()

expr5b = (x^2)^3
println("Expression: (x²)³")
println("Simplified: ", Simplify(expr5b))
println("Expected: x⁶")
println()

# Test 6: Exponential rules
println("Test 6: Exponential Rules")
println("-" ^ 40)
expr6 = exp(x) * exp(y)
println("Expression: exp(x) * exp(y)")
println("Simplified: ", Simplify(expr6))
println("Expected: exp(x + y)")
println()

expr6b = exp(x) / exp(y)
println("Expression: exp(x) / exp(y)")
println("Simplified: ", Simplify(expr6b))
println("Expected: exp(x - y)")
println()

# Test 7: Power multiplication rules
println("Test 7: Power Multiplication Rules")
println("-" ^ 40)
expr7 = x^2 * x^3
println("Expression: x² * x³")
println("Simplified: ", Simplify(expr7))
println("Expected: x⁵")
println()

expr7b = x^5 / x^2
println("Expression: x⁵ / x²")
println("Simplified: ", Simplify(expr7b))
println("Expected: x³")
println()

# Test 8: Basic algebraic simplification (already working)
println("Test 8: Basic Algebraic Simplification")
println("-" ^ 40)
expr8 = 2*x + 3*x
println("Expression: 2x + 3x")
println("Simplified: ", Simplify(expr8))
println("Expected: 5x")
println()

# Test 9: Trigonometric negation
println("Test 9: Trigonometric Negation")
println("-" ^ 40)
expr9a = sin(-x)
println("Expression: sin(-x)")
println("Simplified: ", Simplify(expr9a))
println("Expected: -sin(x)")
println()

expr9b = cos(-x)
println("Expression: cos(-x)")
println("Simplified: ", Simplify(expr9b))
println("Expected: cos(x)")
println()

# Test 10: Constant evaluation
println("Test 10: Constant Evaluation")
println("-" ^ 40)
expr10 = exp(0)
println("Expression: exp(0)")
println("Simplified: ", Simplify(expr10))
println("Expected: 1")
println()

expr10b = log(1)
println("Expression: log(1)")
println("Simplified: ", Simplify(expr10b))
println("Expected: 0")
println()

println("=" ^ 60)
println("All tests completed!")
println("=" ^ 60)
