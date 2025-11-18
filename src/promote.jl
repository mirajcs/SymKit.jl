#Promote numbers to Const
promote_expr(x::SymExpr) = x 
promote_expr(x::Number) = Const(x)
