module SymKit


export Sym, @sym, Const, UnaryOp, BinaryOp, promote_expr, Simplify, Derivative

#Other modules
include("types.jl")
include("macro.jl")
include("operations.jl")
include("promote.jl")
include("prettyprinting.jl")
include("simplifications.jl")
include("differentiate.jl")







end # module SymKit
