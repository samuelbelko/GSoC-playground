"""
Use for surrogates that don't need hyperparameter optimization.

A consequence of `updated` being `false` at all times, is that we always use `add_point!`
when updating the corresponding local surrogate.
"""
struct VoidHyperparameterHandler <: HyperparameterHandler
    θ::NamedTuple
    updated::Bool
end

function VoidHyperparameterHandler(init_xs::Vector{Vector{Float64}}, init_ys::Vector{Float64})
    if length(init_xs) == 0 || length(init_xs) != length(init_ys)
        throw(ArgumentError("initial sampling is empty, cannot initialize hyperparameters"))
    end
    dimension = length(init_xs[1])
    VoidHyperparameterHandler((; lengthscales = ones(dimension)), false)
end

function update_hyperparameters!(xs, ys, hh::VoidHyperparameterHandler)
    nothing
end
