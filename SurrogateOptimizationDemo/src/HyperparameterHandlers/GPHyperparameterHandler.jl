"""
Maintain and update hyperparameters (lengthscale, signal variance, noise variance)
for a GP surrogate.
"""
mutable struct  GPHyperparameterHandler <: HyperparameterHandler
    lengthscales::Vector{Float64}
    signal_var::Float64
    noise_var::Float64

    lengthscales_bounds::Tuple{Float64}
    signal_var_bounds::Tuple{Float64}
    noise_var_bounds::Tuple{Float64}

    # updated flag:
    # controls if we use add_point! to add new points to existing surrogate or
    # train a new surrogate using a new set of hyperparameters and its corresponding
    # history xs data
    updated::Bool
end

# function GPHyperparameterHandler()
#     GPHyperparameterHandler(, )
# end


function update_hyperparameters!(xs, ys, hh::GPHyperparameterHandler)
    # compute optimizers of loss(xs, ys, lengthscales, signal_var, noise_var)

    # if other params, set updated = true, else to false
end
