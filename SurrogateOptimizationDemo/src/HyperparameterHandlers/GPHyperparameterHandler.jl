"""
Maintain and update hyperparameters (lengthscale, signal variance, noise variance)
for a GP surrogate.
"""
mutable struct GPHyperparameterHandler <: HyperparameterHandler
    # save parameters and their bounds in θ
    θ::NamedTuple

    # updated flag:
    # controls if we use add_point! to add new points to existing surrogate or
    # train a new surrogate using a new set of hyperparameters and its corresponding
    # history xs data
    updated::Bool
end

function GPHyperparameterHandler(init_xs::Vector{Vector{Float64}}, init_ys::Vector{Float64})
    if length(init_xs) == 0 || length(init_xs) != length(init_ys)
        throw(ArgumentError("initial sampling is empty, cannot initialize hyperparameters"))
    end
    dimension = length(init_xs[1])
    # use bounds from the paper,
    # lengthscale λ_i in [0.005,2.0], signal variance s^2 in [0.05,20.0], noise var. σ^2 in [0.0005,0.1]
    # TODO: compute initial hyperparams from init_xs, init_ys, see https://infallible-thompson-49de36.netlify.app/
    θ_init = (;
        lengthscales = bounded(ones(dimension), 0.005, 2.0),
        signal_var = bounded(1.0, 0.05,20.0),
        noise_var = bounded(0.09, 0.0005, 0.1)
    )
    GPHyperparameterHandler(θ_init, false)
end


function create_kernel(θ)
    θ.signal_var * with_lengthscale(Matern52Kernel(),  θ.lengthscales)
end

# code snippets adopted from:
# https://juliagaussianprocesses.github.io/AbstractGPs.jl/dev/examples/1-mauna-loa/
# and https://github.com/JuliaGaussianProcesses/ParameterHandling.jl
function negative_lml(xs, ys, θ)
    # prior process
    f = GP(create_kernel(θ), Σy = θ.noise_var)
    # finite projection at xs
    fx = f(xs)
    # negative log marginal likelihood of posterior
    -logpdf(fx, ys)
end

function setup_loss(xs, ys)
    (θ) -> negative_lml(xs, ys, θ)
end

default_optimizer = LBFGS(;
    alphaguess=Optim.LineSearches.InitialStatic(; scaled=true),
    linesearch=Optim.LineSearches.BackTracking(),
)

function optimize_loss(xs, ys, θ_init; optimizer=default_optimizer, maxiter=1_000)
    loss = setup_loss(xs,ys)
    options = Optim.Options(; iterations=maxiter, show_trace=true)

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

    result = optimize(Optim.only_fg!(fg!), θ_flat_init, optimizer, options; inplace=false)
    println(result)

    return unflatten(result.minimizer)
end


function update_hyperparameters!(xs, ys, hh::GPHyperparameterHandler)
    # TODO: start optmization more times with different init. params
    init_params = init_hyperparameters(xs,ys,hh.lengthscales_bounds,hh.noise_var_bounds,hh.signal_var_bounds)
    θ_opt = optimize_loss(loss, θ_init)
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
    AbstractGPSurrogate(xs, ys, gp = GP(create_kernel(hh.θ)), Σy = hh.θ.noise_var)
end
