module SymKit


export Sym, @sym, Const, UnaryOp, BinaryOp, promote_expr, Simplify, Derivative,
       Evaluate, hasVariable, Denominator, Singularities,
       Limit, CheckDivisionLimits, DivisionBehavior

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
