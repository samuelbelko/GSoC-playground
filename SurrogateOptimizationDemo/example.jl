# not yet working as expected..
using Pkg
Pkg.activate("./SurrogateOptimizationDemo")

# using Plots
# plotlyjs()

using SurrogatesAbstractGPs

using SurrogateOptimizationDemo
rx,ry = rand(),rand()

# f(x) = -(x[1] - rx)^2 - (x[2] - ry)^2

# copied from BaysianOptimization.jl
branin(x::Vector; kwargs...) = branin(x[1], x[2]; kwargs...)
function branin(x1, x2; a = 1, b = 5.1 / (4π^2), c = 5 / π, r = 6, s = 10, t = 1 / (8π),
                noiselevel = 0)
    x1, x2 = SurrogateOptimizationDemo.from_unit_cube([x1, x2] , -20, 25)
    - a * (x2 - b * x1^2 + c * x1 - r)^2 + s * (1 - t) * cos(x1) + s + noiselevel * randn()
end

function create_surrogate(xs, ys)
    # create an object of type surrogate_type which is a subtype of AbstractSurrogate
    AbstractGPSurrogate(xs, ys)
end

oh = OptimizationHelper(branin, 2, 50)
dsm = Turbo(2, 2, 5, 2, create_surrogate)
policy = TurboPolicy(2)

initialize!(dsm, oh)

begin
    plt  = scatter((x -> x[1]).(oh.hist_xs), (x -> x[2]).(oh.hist_xs), oh.hist_ys)
    plt = surface!(0:0.1:1,0:0.1:1, (x,y) -> branin([x,y]))
    plt
end

optimize!(dsm, policy, oh)
