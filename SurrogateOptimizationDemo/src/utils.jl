"""
Log number of function evaluations and times.
"""
function eval_fun(oh::OptimizationHelper, f, xs)
    # TODO: increse evaluation counter, duration time in oh
    # time = ...
    log_eval!(oh, time)
    f.(xs)
end

# copied from https://github.com/jbrea/BayesianOptimization.jl/blob/master/src/utils.jl
import Base: iterate, length
struct ScaledSobolIterator{T, D}
    lowerbounds::Vector{T}
    upperbounds::Vector{T}
    N::Int
    seq::SobolSeq{D}
end

"""
    ScaledSobolIterator(lowerbounds, upperbounds, N;
                        seq = SobolSeq(length(lowerbounds)))

Returns an iterator over `N` elements of a Sobol sequence between `lowerbounds`
and `upperbounds`. The first `N` elements of the Sobol sequence are skipped for
better uniformity (see https://github.com/stevengj/Sobol.jl)
"""
function ScaledSobolIterator(lowerbounds, upperbounds, N;
                             seq = SobolSeq(length(lowerbounds)))
    N > 0 && skip(seq, N)
    ScaledSobolIterator(lowerbounds, upperbounds, N, seq)
end
length(it::ScaledSobolIterator) = it.N
@inline function iterate(it::ScaledSobolIterator, s = 1)
    s == it.N + 1 && return nothing
    Sobol.next!(it.seq, it.lowerbounds, it.upperbounds), s + 1
end
