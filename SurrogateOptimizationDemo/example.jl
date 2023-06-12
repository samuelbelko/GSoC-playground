# not yet working as expected..
using Pkg
Pkg.activate("./SurrogateOptimizationDemo")

using Plots
plotlyjs()

using SurrogatesAbstractGPs
using SurrogateOptimizationDemo

#rx, ry = rand(), rand()
# f(x) = -(x[1] - rx)^2 - (x[2] - ry)^2

# copied from BaysianOptimization.jl
branin(x::Vector; kwargs...) = branin(x[1], x[2]; kwargs...)
function branin(x1, x2; a = 1, b = 5.1 / (4π^2), c = 5 / π, r = 6, s = 10, t = 1 / (8π),
                noiselevel = 0)
    a * (x2 - b * x1^2 + c * x1 - r)^2 + s * (1 - t) * cos(x1) + s + noiselevel * randn()
end

function create_surrogate(xs, ys)
    # create an object of type surrogate_type which is a subtype of AbstractSurrogate
    AbstractGPSurrogate(xs, ys)
end

lb, ub = [-10,-10], [15,15]
oh = OptimizationHelper(branin, 2, Min, lb, ub, 50)
dsm = Turbo(2, 2, 5, 2, create_surrogate)
policy = TurboPolicy(2)

initialize!(dsm, oh)

begin
    plt = scatter((x -> x[1]).(get_hist(oh)[1]), (x -> x[2]).(get_hist(oh)[1]), get_hist(oh)[2])
    plt = surface!(-10:0.1:15, -10:0.1:15, (x, y) -> -branin([x, y]))
    plt
end

optimize!(dsm, policy, oh)
