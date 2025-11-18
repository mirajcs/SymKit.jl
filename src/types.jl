abstract type SymExpr end

#core symbolic expression types 

#symbols
struct Sym <: SymExpr 
    name::Symbol 
end

#numbers
struct Const <: SymExpr
    value::Number 
end 

#for sin, cos, ext, ln etc. 
struct UnaryOp <: SymExpr 
    op::Symbol
    arg::SymExpr
end

#binary operations
struct BinaryOp <: SymExpr
    op::Symbol
    left::SymExpr
    right::SymExpr
end