"""
Use for surrogates that don't need hyperparamter optimization.

A consequence of `updated` being `false` at all times, is that we always use `add_point!`
when updating the corresponding local surrogate.
"""
struct VoidHyperparameterHandler <: HyperparameterHandler
    lengthscales::Vector{Float64}
    updated::Bool
end

function VoidHyperparameterHandler(dimension)
    VoidHyperparameterHandler(ones(dimension), false)
end
