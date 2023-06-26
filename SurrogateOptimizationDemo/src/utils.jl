"""
Affine linear map from [lb, ub] to [0,1]^dim.
"""
function to_unit_cube(x, lb, ub)
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    (x .- lb) ./ (ub .- lb)
end

"""
Affine linear map from [0,1]^dim to [lb, ub].
"""
function from_unit_cube(x, lb, ub)
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    x .* (ub .- lb) .+ lb
end

# copied from https://github.com/jbrea/BayesianOptimization.jl/blob/master/src/utils.jl
# import Base: iterate, length
# struct ScaledSobolIterator{T, D}
#     lowerbounds::Vector{T}
#     upperbounds::Vector{T}
#     N::Int
#     seq::SobolSeq{D}
# end

# """
#     ScaledSobolIterator(lowerbounds, upperbounds, N;
#                         seq = SobolSeq(length(lowerbounds)))

# Returns an iterator over `N` elements of a Sobol sequence between `lowerbounds`
# and `upperbounds`. The first `N` elements of the Sobol sequence are skipped for
# better uniformity (see https://github.com/stevengj/Sobol.jl)
# """
# function ScaledSobolIterator(lowerbounds, upperbounds, N;
#                              seq = SobolSeq(length(lowerbounds)))
#     N > 0 && skip(seq, N)
#     ScaledSobolIterator(lowerbounds, upperbounds, N, seq)
# end
# length(it::ScaledSobolIterator) = it.N
# @inline function iterate(it::ScaledSobolIterator, s = 1)
#     s == it.N + 1 && return nothing
#     Sobol.next!(it.seq, it.lowerbounds, it.upperbounds), s + 1
# end
