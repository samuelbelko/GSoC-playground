using Pkg
# assuming we are at GSoC-playground folder
Pkg.activate("./SurrogateOptimizationDemo")

using Plots, LinearAlgebra
using AbstractGPs # access to kernels

#plotlyjs()
gr()

using Surrogates
using SurrogatesAbstractGPs
# using Flux, SurrogatesFlux
using SurrogateOptimizationDemo

# copied from BaysianOptimization.jl
# shift x1, x2 by Δ, b/c inital sampling is randomly almost hitting an optimum
Δ = 2.5
branin(x::Vector; kwargs...) = branin(x[1], x[2]; kwargs...)
function branin(x1, x2; a = 1, b = 5.1 / (4π^2), c = 5 / π, r = 6, s = 10, t = 1 / (8π),
                noiselevel = 0)
    x1 += Δ
    x2 += Δ
    a * (x2 - b * x1^2 + c * x1 - r)^2 + s * (1 - t) * cos(x1) + s + noiselevel * randn()
end
minima(::typeof(branin)) = [[-π - Δ, 12.275 - Δ], [π - Δ, 2.275 - Δ], [9.42478 - Δ, 2.475 - Δ]], 0.397887
mins, fmin = minima(branin)

# --- GPs with hyperopt. -----
function create_surrogate(xs, ys, hh::GPHyperparameterHandler)
    create_GP_surrogate(xs, ys, hh)
end
function create_hyperparameter_handler(init_xs, init_ys)
    GPHyperparameterHandler(init_xs, init_ys)
end
# -------

# --- GPs without hyperparm. optimization --------
# function create_surrogate(xs, ys, hh::VoidHyperparameterHandler)
#     # hh is not used to create a kernel
#     AbstractGPSurrogate(xs, ys, gp = GP(Matern52Kernel()), Σy = 0.1)
# end
# function create_hyperparameter_handler(init_xs, init_ys)
#     VoidHyperparameterHandler(init_xs, init_ys)
# end
# -------

#--- SecondOrderPolynomialSurrogate without hyperopt. --
# function create_surrogate(xs, ys, hh::VoidHyperparameterHandler)
#     SecondOrderPolynomialSurrogate(xs, ys,[-15, -15], [15, 15])
# end
# function create_hyperparameter_handler(init_xs, init_ys)
#     VoidHyperparameterHandler(init_xs, init_ys)
# end
#-------

# --- neural network as a surrogate without hyperopt. --
# model1 = Chain(
#   Dense(2, 5, σ),
#   Dense(5,2,σ),
#   Dense(2, 1)
# )
# function create_surrogate(xs, ys, hh::VoidHyperparameterHandler)
#     NeuralSurrogate(xs, ys,[-15, -15], [15, 15],model = model1, n_echos = 10)
# end
# function create_hyperparameter_handler(init_xs, init_ys)
#     VoidHyperparameterHandler(init_xs, init_ys)
# end
# -------

# lb = left bottom point in domain, ub = top right point in domain
lb, ub = [-15, -15], [15, 15]
# instantiate OptimizationHelper
oh = OptimizationHelper(branin, Min, lb, ub, 200)
# instantiate DecisionSupportModel
# n_surrogates, batch_size, n_init_for_local, dimension, create_surrogate, create_hyperparameter_handler
dsm = Turbo(3, 5, 10, 2, create_surrogate, create_hyperparameter_handler)
# instantiate a compatible policy, i.e., we can obtain next evaluation point via `policy(dsm)`
policy = TurboPolicy(2)
# run initial sampling, create initial trust regions and local models
initialize!(dsm, oh)

function p()
    plt = contour(-15:0.1:15, -15:0.1:15, (x, y) -> -branin([x, y]), levels = 80,
                  fill = true)
    plt = scatter!((x -> x[1]).(get_hist(oh)[1]), (x -> x[2]).(get_hist(oh)[1]),
                   label = "eval. hist")
    plt = scatter!((x -> x[1]).(mins), (y -> y[2]).(mins), label = "true minima",
                   markersize = 10, shape = :diamond)
    plt = scatter!([get_solution(oh)[1][1]], [get_solution(oh)[1][2]],
                   label = "observed min.", shape = :rect)
    plt
end

# savefig(p(), "plot_before_optimization.png")
display(p())

# Optimize
optimize!(dsm, policy, oh)

# savefig(p(), "plot_after_optimization.png")
display(p())

observed_dist = minimum((m -> norm(get_solution(oh)[1] .- m)).(mins))
observed_regret = abs(get_solution(oh)[2] - fmin)
