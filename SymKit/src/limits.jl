# Limit calculation and left/right-handed limit checking

"""
    limit(expr::SymExpr, var::Sym, point::Number; direction=:both, epsilon=1e-6)

Calculate the limit of an expression as a variable approaches a point.

Arguments:
- expr: The expression to evaluate
- var: The variable approaching the point
- point: The point being approached
- direction: :left (x→point⁻), :right (x→point⁺), or :both (check both)
- epsilon: Step size for numerical approximation

Returns:
- A symbolic value or :undefined, :inf, :-inf, :nan
- For :both direction, returns (:left_result, :right_result)

Example:
    x = Sym(:x)
    expr = 1 / x
    limit(expr, x, 0; direction=:left)   # Approaches -∞
    limit(expr, x, 0; direction=:right)  # Approaches +∞
"""
function limit(expr::SymExpr, var::Sym, point::Number; direction=:both, epsilon=1e-6)
    if direction == :both
        return (limit(expr, var, point; direction=:left, epsilon=epsilon),
                limit(expr, var, point; direction=:right, epsilon=epsilon))
    end

    # Determine the direction of approach
    step = direction == :left ? -epsilon : epsilon

    # Evaluate at multiple points approaching the limit
    # Use a sequence that converges to the point
    max_iterations = 50
    results = []

    for i in 1:max_iterations
        # Get closer to the point each iteration: point + step / (2^i)
        test_point = point + step / (2^i)

        try
            result = evaluate(expr, var, test_point)
            if result isa Const
                push!(results, result.value)
            else
                # If not a constant, can't evaluate numerically
                return :undefined
            end
        catch _
            # If evaluation fails, return undefined
            return :undefined
        end
    end

    if isempty(results)
        return :undefined
    end

    # Analyze the sequence of results to determine the limit
    last_value = results[end]
    prev_value = results[end-1]

    # Check for divergence to infinity
    if last_value > 1e10 && prev_value > 1e10
        return :inf
    elseif last_value < -1e10 && prev_value < -1e10
        return Symbol("-inf")
    elseif isinf(last_value) || isnan(last_value)
        if last_value > 0 || (isinf(last_value) && step > 0)
            return :inf
        else
            return Symbol("-inf")
        end
    else
        # Finite limit - return the limit value
        return Const(last_value)
    end
end

"""
    check_division_limits(expr::SymExpr, var::Sym)

Check for division by zero and compute left/right-handed limits at singularities.

Returns a dictionary with:
- :has_singularity::Bool - whether division by zero exists
- :singularities::Vector - list of singularity information
- :left_limit - left-handed limit at each singularity
- :right_limit - right-handed limit at each singularity

Example:
    x = Sym(:x)
    expr = 1 / (x - 2)
    result = check_division_limits(expr, x)
    # Returns info about singularity at x=2
"""
function check_division_limits(expr::SymExpr, var::Sym; epsilon=1e-6)
    singularities = find_singularities(expr, var)
    result = Dict(
        :has_singularity => false,
        :singularities => [],
    )

    for denom in singularities
        # Try to evaluate the denominator to find zeros
        # First, check if it's a simple polynomial we can analyze

        # For now, use numerical methods to check for zeros
        # Sample the denominator at various points
        test_points = -10:1:10
        for test_point in test_points
            try
                denom_val = evaluate(denom, var, test_point)
                if denom_val isa Const && abs(denom_val.value) < 1e-10
                    # Found a potential singularity
                    result[:has_singularity] = true

                    # Compute left and right limits
                    left_lim = limit(expr, var, test_point; direction=:left, epsilon=epsilon)
                    right_lim = limit(expr, var, test_point; direction=:right, epsilon=epsilon)

                    push!(result[:singularities], Dict(
                        :point => test_point,
                        :denominator => denom,
                        :left_limit => left_lim,
                        :right_limit => right_lim,
                        :continuous => left_lim == right_lim,
                    ))
                end
            catch _
                # Continue if evaluation fails
            end
        end
    end

    return result
end

"""
    describe_division_behavior(expr::SymExpr, var::Sym)

Provide a human-readable description of division behavior at singularities.

Returns a string describing the limits and behavior.

Example:
    x = Sym(:x)
    expr = 1 / (x - 2)
    describe_division_behavior(expr, x)
    # Returns: "Division by zero at x=2. Left limit: -∞, Right limit: +∞"
"""
function describe_division_behavior(expr::SymExpr, var::Sym)
    analysis = check_division_limits(expr, var)

    if !analysis[:has_singularity]
        return "No division by zero detected"
    end

    descriptions = []
    for sing in analysis[:singularities]
        point = sing[:point]
        left = sing[:left_limit]
        right = sing[:right_limit]

        left_str = format_limit_value(left)
        right_str = format_limit_value(right)

        desc = "At $(var.name)=$(point): "
        if sing[:continuous]
            desc *= "Continuous (left = right = $left_str)"
        else
            desc *= "Discontinuous - Left limit: $left_str, Right limit: $right_str"
        end

        push!(descriptions, desc)
    end

    return join(descriptions, "\n")
end

"""
    format_limit_value(val)

Format a limit value for display.
"""
function format_limit_value(val)
    if val == :inf
        return "+∞"
    elseif val == :-inf
        return "-∞"
    elseif val == :undefined
        return "undefined"
    elseif val == :nan
        return "NaN"
    elseif val isa Const
        return string(round(val.value; digits=4))
    else
        return string(val)
    end
end
