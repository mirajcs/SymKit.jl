macro sym(args...)
    # Create assignments: var = Sym(:var)
    if length(args) == 1
        # Single argument: @sym x → x = Sym(:x); return x
        arg = args[1]
        return quote
            $(esc(arg)) = Sym($(QuoteNode(arg)))
        end
    else
        # Multiple arguments: @sym x y → x = Sym(:x); y = Sym(:y); return (x, y)
        assignments = [:($(esc(arg)) = Sym($(QuoteNode(arg)))) for arg in args]
        return quote
            $(assignments...)
            ($(esc.(args)...),)
        end
    end
end
