"""
Initialize, maintain and update hyperparameters for a surrogate.

If it is used for a local surrogate in Turbo, it needs to at least include fields

    θ::NamedTuple
    updated::Bool

with `θ` having an entry `lengthscales` used for stretching a trust region.
It should provide method `update_hyperparameters!(hh::HyperparameterHandler)`.
"""
abstract type HyperparameterHandler end

"""
Run hyperparameter optimization on evalutations `ys` at points `xs`.
"""
function update_hyperparameters!(xs, ys, hh::HyperparameterHandler) end

"""
Retrieve `lengthscales` hyperparameter.
"""
function get_lengthscales(hh::HyperparameterHandler)
    ParameterHandling.value(hh.θ.lengthscales)
end
