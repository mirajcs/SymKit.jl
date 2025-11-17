module SymKit


export Sym, @sym, Const, UnaryOp, BinaryOp, promote_expr, Simplify, Derivative,
       evaluate, has_variable, get_denominator, find_singularities,
       limit, check_division_limits, describe_division_behavior

#Other modules
include("types.jl")
include("macro.jl")
include("operations.jl")
include("promote.jl")
include("prettyprinting.jl")
include("simplifications.jl")
include("differentiate.jl")
include("evaluate.jl")
include("limits.jl")







end # module SymKit
