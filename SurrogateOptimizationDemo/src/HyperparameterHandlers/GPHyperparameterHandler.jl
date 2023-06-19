"""
Maintain and update hyperparameters (lengthscale, signal variance, noise variance)
for a GP surrogate.
"""
mutable struct GPHyperparameterHandler <: HyperparameterHandler
    lengthscales::Vector{Float64}
    signal_var::Float64
    noise_var::Float64

    lengthscales_bounds::NTuple{2, Float64}
    signal_var_bounds::NTuple{2, Float64}
    noise_var_bounds::NTuple{2, Float64}

    # updated flag:
    # controls if we use add_point! to add new points to existing surrogate or
    # train a new surrogate using a new set of hyperparameters and its corresponding
    # history xs data
    updated::Bool
end

function GPHyperparameterHandler(init_xs, init_ys)
    # use bounds from the paper,
    # lengthscale λ_i in [0.005,2.0], signal variance s^2 in [0.05,20.0], noise var. σ^2 in [0.0005,0.1]
    lengthscales_bounds = (0.005, 2.0)
    signal_var_bounds = (0.05, 20.0)
    noise_var_bounds = (0.0005, 0.1)

    lengthscales, signal_var, noise_var = init_hyperparameters(init_xs, init_ys,
                                                               lengthscales_bounds,
                                                               signal_var_bounds,
                                                               noise_var_bounds)
    GPHyperparameterHandler(lengthscales, signal_var, noise_var,
                            lengthscales_bounds, signal_var_bounds, noise_var_bounds, false)
end

function init_hyperparameters(init_xs, init_ys, lengthscales_bounds, signal_var_bounds,
                              noise_var_bounds)
    if length(init_xs) == 0 || length(init_xs) != length(init_ys)
        throw(ArgumentError("initial sampling is empty, cannot initialize hyperparameters"))
    end
    # TODO!!! how to initalize hyperparams?
    # see https://infallible-thompson-49de36.netlify.app/
    # lengthscales =
    # signal_var =
    # noise_var =
    # TODO: make sure they are in respective bounds
    ones(length(init_xs[1])), 1.0, 0.1
end

function update_hyperparameters!(xs, ys, hh::GPHyperparameterHandler)
    # compute optimizers of loss(xs, ys, lengthscales, signal_var, noise_var)

    # check if within bounds
    # if other params, set updated = true, else to false
end
