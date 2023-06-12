using Pkg
Pkg.activate("./SurrogateOptimizationDemo")

using Plots
using LinearAlgebra
using AbstractGPs # access to kernels

#plotlyjs()
gr()

using SurrogatesAbstractGPs
using SurrogateOptimizationDemo

# copied from BaysianOptimization.jl
branin(x::Vector; kwargs...) = branin(x[1], x[2]; kwargs...)
function branin(x1, x2; a = 1, b = 5.1 / (4π^2), c = 5 / π, r = 6, s = 10, t = 1 / (8π),
    noiselevel = 0)
    a * (x2 - b * x1^2 + c * x1 - r)^2 + s * (1 - t) * cos(x1) + s + noiselevel * randn()
end
minima(::typeof(branin)) = [[-π, 12.275], [π, 2.275], [9.42478, 2.475]], 0.397887
mins, fmin = minima(branin)

function create_surrogate(xs, ys)
    # create an object of type surrogate_type which is a subtype of AbstractSurrogate
    AbstractGPSurrogate(xs, ys, gp = GP(Matern52Kernel()), Σy = 0.1)
end

lb, ub = [-10,-10], [15,15]
oh = OptimizationHelper(branin, Min, lb, ub, 1000)
dsm = Turbo(5, 10, 10, 2, create_surrogate)
policy = TurboPolicy(2)

initialize!(dsm, oh)

begin
    plt = contour(-10:0.1:15, -10:0.1:15, (x, y) -> -branin([x, y]), levels=80, fill =true)
    plt = scatter!((x -> x[1]).(get_hist(oh)[1]), (x -> x[2]).(get_hist(oh)[1]), label="eval. hist")
    plt = scatter!((x -> x[1]).(mins), (y -> y[2]).(mins), label="true minima", markersize=10,shape=:diamond)
    plt = scatter!([get_solution(oh)[1][1]], [get_solution(oh)[1][2]], label="observed min.",shape=:rect)
end

optimize!(dsm, policy, oh)

observed_dist = minimum((m -> norm(get_solution(oh)[1] .- m)).(mins))
observed_regret = abs(get_solution(oh)[2] - fmin)
