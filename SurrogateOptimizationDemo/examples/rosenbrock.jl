using Pkg
# assuming we are at GSoC-playground folder
Pkg.activate("./SurrogateOptimizationDemo")

using Plots, LinearAlgebra
using AbstractGPs # access to kernels

#plotlyjs()
gr()

using Surrogates
using SurrogatesAbstractGPs
using SurrogateOptimizationDemo

rosenbrock(x::Vector; kwargs...) = rosenbrock(x[1], x[2]; kwargs...)
# non-convex function
rosenbrock(x1, x2) = 100*(x2 - x1^2)^2 + (1-x1)^2

minima(::typeof(rosenbrock)) = [[1,1]], 0
mins, fmin = minima(rosenbrock)

# --- GPs with hyperopt. -----
function create_surrogate(xs, ys, hh::GPHyperparameterHandler)
    create_GP_surrogate(xs, ys, hh)
end
function create_hyperparameter_handler(init_xs, init_ys)
    GPHyperparameterHandler(init_xs, init_ys)
end
# -------

# lb = left bottom point in domain, ub = top right point in domain
lb, ub = [-2, -1], [2, 2]
# instantiate OptimizationHelper
oh = OptimizationHelper(rosenbrock, Min, lb, ub, 200)
# instantiate DecisionSupportModel
# n_surrogates, batch_size, n_init_for_local, dimension, create_surrogate, create_hyperparameter_handler
dsm = Turbo(2, 5, 10, 2, create_surrogate, create_hyperparameter_handler)
# instantiate a compatible policy, i.e., we can obtain next evaluation point via `policy(dsm)`
policy = TurboPolicy(2)
# run initial sampling, create initial trust regions and local models
initialize!(dsm, oh)

function p()
    plt = contour(-2:0.1:2, -1:0.1:2, (x, y) -> -rosenbrock([x, y]), levels = 500,
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
