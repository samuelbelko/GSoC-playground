# not yet working as expected..
using Pkg
Pkg.activate("./SurrogateOptimizationDemo")

using Plots
plotlyjs()

using SurrogatesAbstractGPs

using SurrogateOptimizationDemo

f(x) = -(x[1] - 0.5) * (x[2] - 0.5)

function create_surrogate(xs, ys)
    # create an object of type surrogate_type which is a subtype of AbstractSurrogate
    AbstractGPSurrogate(xs, ys)
end

oh = OptimizationHelper(f, 2, 10^4)
dsm = Turbo(3, 20, 10, 2, create_surrogate)
policy = TurboPolicy(2)

initialize!(dsm, oh)

# scatter((x -> x[1]).(oh.hist_xs), (x -> x[2]).(oh.hist_xs), oh.hist_ys)

optimize!(dsm, policy, oh)
