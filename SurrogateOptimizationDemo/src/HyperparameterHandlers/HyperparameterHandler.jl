"""
Initialize, maintain and update hyperparameters for a local surrogate.

If it is used for a local surrogate in Turbo, it needs to at least include fields as
in `VoidHyperparameterHandler` and provide method `update_hyperparameters!(hh::HyperparameterHandler)`.
"""
abstract type HyperparameterHandler end

"""
Run hyperparameter optimization.
"""
function update_hyperparameters!(hh::HyperparameterHandler) end

"""
Retrieve `lengthscales` hyperparameter.
"""
function get_lengthscales(hh::HyperparameterHandler)
    ParameterHandling.value(hh.θ.lengthscales)
end
