#basic arithmatic operations 

Base.:+(a::Union{SymExpr,Number},b::Union{SymExpr,Number}) = BinaryOp(:+,promote_expr(a),promote_expr(b))
Base.:-(a::Union{SymExpr,Number},b::Union{SymExpr,Number}) = BinaryOp(:-,promote_expr(a),promote_expr(b))
Base.:*(a::Union{SymExpr,Number},b::Union{SymExpr,Number}) = BinaryOp(:*,promote_expr(a),promote_expr(b))
Base.:/(a::Union{SymExpr,Number},b::Union{SymExpr,Number}) = BinaryOp(:/,promote_expr(a),promote_expr(b))
Base.:^(a::Union{SymExpr,Number},b::Union{SymExpr,Number}) = BinaryOp(:^,promote_expr(a),promote_expr(b))
Base.:-(a::SymExpr) =  UnaryOp(:-, a)

# Unary mathematical functions
Base.sqrt(a::Union{SymExpr,Number}) = UnaryOp(:sqrt, promote_expr(a))
Base.abs(a::Union{SymExpr,Number}) = UnaryOp(:abs, promote_expr(a))