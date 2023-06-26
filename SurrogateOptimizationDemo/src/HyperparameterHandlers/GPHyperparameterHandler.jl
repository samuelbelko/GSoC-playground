"""
Initialize, maintain and update hyperparameters (lengthscale, signal variance, noise variance)
for a GP surrogate.
"""
mutable struct GPHyperparameterHandler <: HyperparameterHandler
    # save current parameters
    θ::NamedTuple
    # bounds from paper for θ
    θ_bounds::NamedTuple
    # updated flag:
    # controls if we use add_point! to add new points to existing surrogate or
    # train a new surrogate using a new set of hyperparameters and its corresponding
    # history xs data
    updated::Bool
end

function GPHyperparameterHandler(init_xs::Vector{Vector{Float64}}, init_ys::Vector{Float64})
    if isempty(init_xs) || length(init_xs) != length(init_ys)
        throw(ArgumentError("initial sampling is empty, cannot initialize hyperparameters"))
    end
    dimension = length(init_xs[1])
    # lengthscale λ_i in [0.005,2.0], signal variance s^2 in [0.05,20.0], noise var. σ^2 in [0.0005,0.1]
    θ_bounds = (lengthscales = (min = 0.005, max = 2.0),
                signal_var = (min = 0.05, max = 20.0),
                noise_var = (min = 0.0005, max = 0.1))
    # hyperparm opt. on init_xs, init_ys
    θ_opt = compute_θ_opt(init_xs, init_ys, θ_bounds)
    GPHyperparameterHandler(θ_opt, θ_bounds, true)
end

function compute_θ_init(xs, ys, θ_bounds)
    if isempty(xs) || length(xs) != length(ys)
        throw(ArgumentError("initial sampling is empty, cannot run compute_θ_init"))
    end
    dimension = length(xs[1])
    # TODO: compute initial hyperparams from init_xs, init_ys, see https://infallible-thompson-49de36.netlify.app/
    θ_init = (;
              lengthscales = bounded(ones(dimension), θ_bounds.lengthscales.min,
                                     θ_bounds.lengthscales.max),
              signal_var = bounded(1.0, θ_bounds.signal_var.min, θ_bounds.signal_var.max),
              noise_var = bounded(0.09, θ_bounds.noise_var.min, θ_bounds.noise_var.max))
end

function create_kernel(θ_val)
    θ_val.signal_var * with_lengthscale(Matern52Kernel(), θ_val.lengthscales)
end

# code snippets adopted from:
# https://juliagaussianprocesses.github.io/AbstractGPs.jl/dev/examples/1-mauna-loa/
# and https://github.com/JuliaGaussianProcesses/ParameterHandling.jl
function negative_lml(xs, ys, θ)
    # prior process
    f = GP(create_kernel(ParameterHandling.value(θ)))
    # finite projection at xs
    fx = f(xs, ParameterHandling.value(θ.noise_var))
    # negative log marginal likelihood of posterior
    -logpdf(fx, ys)
end

function setup_loss(xs, ys)
    (θ) -> negative_lml(xs, ys, θ)
end

default_optimizer = LBFGS(;
                          alphaguess = Optim.LineSearches.InitialStatic(; scaled = true),
                          linesearch = Optim.LineSearches.BackTracking())

function minimize(loss, θ_init; optimizer = default_optimizer, maxiter = 1_000)
    options = Optim.Options(; iterations = maxiter, show_trace = false)

    θ_flat_init, unflatten = ParameterHandling.value_flatten(θ_init)
    loss_packed = loss ∘ unflatten

    # https://julianlsolvers.github.io/Optim.jl/stable/#user/tipsandtricks/#avoid-repeating-computations
    function fg!(F, G, x)
        if F !== nothing && G !== nothing
            val, grad = Zygote.withgradient(loss_packed, x)
            G .= only(grad)
            return val
        elseif G !== nothing
            grad = Zygote.gradient(loss_packed, x)
            G .= only(grad)
            return nothing
        elseif F !== nothing
            return loss_packed(x)
        end
    end
    result = optimize(Optim.only_fg!(fg!), θ_flat_init, optimizer, options; inplace = false)
    println("hyperparameter opt. run")
    return unflatten(result.minimizer)
end

function compute_θ_opt(xs, ys, θ_bounds)
    # TODO: start optimization more times with different init. params
    θ_init = compute_θ_init(xs, ys, θ_bounds)
    loss = setup_loss(xs, ys)
    return minimize(loss, θ_init)
end

function update_hyperparameters!(xs, ys, hh::GPHyperparameterHandler)
    θ_opt = compute_θ_opt(xs, ys, hh.θ_bounds)
    if ParameterHandling.value(θ_opt) != hh.θ
        hh.θ = ParameterHandling.value(θ_opt)
        hh.updated = true
    else
        hh.updated = false
    end
end

# --- related utilities but not for hyperparameter optimization ---

# create AbstractGPSurrogate (not GP from AbstractGPs) using parameters in hh
function create_GP_surrogate(xs, ys, hh::GPHyperparameterHandler)
    AbstractGPSurrogate(xs, ys, gp = GP(create_kernel(ParameterHandling.value(hh.θ))),
                        Σy = ParameterHandling.value(hh.θ.noise_var))
end
