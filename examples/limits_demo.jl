"""
SymKit Limits and Division Analysis Demo

This example demonstrates the new limit checking and division by zero analysis
functionality in SymKit. It shows how to:

1. Evaluate expressions at specific points
2. Check for division by zero scenarios
3. Calculate left and right-handed limits at singularities
4. Get detailed descriptions of discontinuities
"""

push!(LOAD_PATH, "/Users/mirajcs/git/SymKit/SymKit/src")
using SymKit

println("=" ^ 70)
println("SymKit Limits and Division Analysis Demo")
println("=" ^ 70)

# Create symbolic variables
@sym x

# Example 1: Simple division by zero at x=0
println("\n1. Analysis of 1/x (division by zero at x=0)")
println("-" ^ 70)
expr1 = 1 / x

# Evaluate at points near 0
println("Evaluating 1/x at different points:")
for point in [-2, -1, -0.1, 0.1, 1, 2]
    result = evaluate(expr1, x, point)
    println("  1/$(point) = $(result.value)")
end

# Check left and right limits at x=0
println("\nLimit analysis at x=0:")
left_lim = limit(expr1, x, 0; direction=:left)
right_lim = limit(expr1, x, 0; direction=:right)
println("  Left-handed limit (x→0⁻): $left_lim")
println("  Right-handed limit (x→0⁺): $right_lim")

# Get full analysis
analysis = check_division_limits(expr1, x)
println("\nDivision singularity analysis:")
println("  Has singularity: $(analysis[:has_singularity])")
for sing in analysis[:singularities]
    println("  - At x=$(sing[:point]):")
    println("    Left limit: $(sing[:left_limit])")
    println("    Right limit: $(sing[:right_limit])")
    println("    Continuous: $(sing[:continuous])")
end

# Get description
println("\nHuman-readable description:")
println(describe_division_behavior(expr1, x))

# Example 2: Rational function with multiple singularities
println("\n\n2. Analysis of 1/(x²-1) (division by zero at x=±1)")
println("-" ^ 70)
expr2 = 1 / (x^2 - 1)

println("Evaluating 1/(x²-1) at different points:")
for point in [-2, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 2]
    result = evaluate(expr2, x, point)
    if result isa Const
        val = result.value
        if isinf(val)
            println("  1/($(point)²-1) = Inf")
        else
            println("  1/($(point)²-1) = $(round(val; digits=4))")
        end
    else
        println("  1/($(point)²-1) = $result")
    end
end

# Analyze at x=1
println("\nLimit analysis at x=1:")
left_lim = limit(expr2, x, 1; direction=:left)
right_lim = limit(expr2, x, 1; direction=:right)
println("  Left-handed limit (x→1⁻): $left_lim")
println("  Right-handed limit (x→1⁺): $right_lim")

# Example 3: Removable singularity
println("\n\n3. Analysis of (x²-1)/(x-1) (removable singularity at x=1)")
println("-" ^ 70)
expr3 = (x^2 - 1) / (x - 1)

println("Evaluating (x²-1)/(x-1) at different points:")
for point in [0, 0.5, 0.9, 0.99, 1.01, 1.1, 1.5, 2]
    result = evaluate(expr3, x, point)
    if result isa Const
        println("  At x=$point: $(round(result.value; digits=4))")
    else
        println("  At x=$point: $result")
    end
end

println("\nLimit analysis at x=1:")
left_lim = limit(expr3, x, 1; direction=:left)
right_lim = limit(expr3, x, 1; direction=:right)
println("  Left-handed limit (x→1⁻): $left_lim")
println("  Right-handed limit (x→1⁺): $right_lim")

# Example 4: Function with no singularities
println("\n\n4. Analysis of x² + 2x + 1 (no singularities)")
println("-" ^ 70)
expr4 = x^2 + 2*x + 1

println("Evaluating x²+2x+1 at different points:")
for point in [-2, -1, 0, 1, 2]
    result = evaluate(expr4, x, point)
    println("  At x=$point: $(result.value)")
end

analysis = check_division_limits(expr4, x)
println("\nDivision singularity analysis:")
println("  Has singularity: $(analysis[:has_singularity])")

if !analysis[:has_singularity]
    println("\nNo division by zero detected - function is continuous everywhere.")
end

println("\n" ^ 2)
println("=" ^ 70)
println("Demo completed!")
println("=" ^ 70)
