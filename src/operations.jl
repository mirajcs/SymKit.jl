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

# Trigonometric functions
Base.sin(a::Union{SymExpr,Number}) = UnaryOp(:sin, promote_expr(a))
Base.cos(a::Union{SymExpr,Number}) = UnaryOp(:cos, promote_expr(a))
Base.tan(a::Union{SymExpr,Number}) = UnaryOp(:tan, promote_expr(a))

# Inverse trigonometric functions
Base.asin(a::Union{SymExpr,Number}) = UnaryOp(:asin, promote_expr(a))
Base.acos(a::Union{SymExpr,Number}) = UnaryOp(:acos, promote_expr(a))
Base.atan(a::Union{SymExpr,Number}) = UnaryOp(:atan, promote_expr(a))

# Exponential and logarithmic functions
Base.exp(a::Union{SymExpr,Number}) = UnaryOp(:exp, promote_expr(a))
Base.log(a::Union{SymExpr,Number}) = UnaryOp(:log, promote_expr(a))