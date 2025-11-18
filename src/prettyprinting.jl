function Base.show(io::IO, s::Sym)
    print(io,s.name)
end

function Base.show(io::IO, c::Const)
    val = c.value
    # Check if it's a simple fraction that can be displayed nicely
    if isa(val, Float64)
        # Check for common fractions
        common_fractions = Dict(
            0.3333333333333333 => "1/3",
            0.6666666666666666 => "2/3",
            0.5 => "1/2",
            0.25 => "1/4",
            0.75 => "3/4",
            -0.3333333333333333 => "-1/3",
            -0.6666666666666667 => "-2/3",
            -0.5 => "-1/2"
        )
        if haskey(common_fractions, val)
            print(io, common_fractions[val])
        else
            print(io, val)
        end
    else
        print(io, val)
    end
end 

function Base.show(io::IO, u::UnaryOp)
    if u.op == :-
        print(io, "-(", u.arg, ")")
    elseif u.op == :sqrt
        # Mathematical radical notation with overline bar
        arg_str = string(u.arg)
        # Use combining overline for better single-line display
        # followed by an overline dash
        print(io, "√‾", arg_str, "‾")
    elseif u.op == :abs
        print(io, "|", u.arg, "|")
    else
        print(io, u.op, "(", u.arg, ")")
    end
end

# Convert number to superscript Unicode characters
function to_superscript(n)
    superscript_map = Dict(
        '0' => '⁰', '1' => '¹', '2' => '²', '3' => '³', '4' => '⁴',
        '5' => '⁵', '6' => '⁶', '7' => '⁷', '8' => '⁸', '9' => '⁹',
        '-' => '⁻', '+' => '⁺', '(' => '⁽', ')' => '⁾', '/' => '⁄'
    )
    result = ""
    for char in string(n)
        result *= get(superscript_map, char, char)
    end
    return result
end

function Base.show(io::IO, b::BinaryOp)
    if b.op == :^
        # Mathematical superscript notation: x²
        if b.right isa Const
            val = b.right.value
            # Check if it's a simple integer exponent (0-9)
            if val == floor(val) && val >= 0 && val <= 9
                # Simple integer exponent - use superscript
                print(io, b.left, to_superscript(Int(val)))
            else
                # Fractional or complex exponent - use caret with parentheses
                print(io, b.left, "^(", b.right, ")")
            end
        else
            # Complex exponent - use caret with parentheses
            print(io, b.left, "^(", b.right, ")")
        end
    elseif b.op == :*
        # Compact multiplication: 2x instead of (2 * x)
        print(io, "(", b.left, " * ", b.right, ")")
    else
        print(io, "(", b.left, " ", b.op, " ", b.right, ")")
    end
end