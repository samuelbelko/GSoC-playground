module SurrogateOptimizationDemo

using Surrogates
using AbstractGPs # access to kernels
using SurrogatesAbstractGPs
import Sobol: SobolSeq

export ask, tell!, optimize!, BasicGP, Turbo, TurboPolicy # and some concrete subtypes of DSMs and Policies

"""
provide funtionalities for aggregation of observations into a decision model used by a policy;
maintain a state of the optimization process (e.g. Trust regions in TuRBO) and surrogates
"""
abstract type DecisionSupportModel end
"""
maintain parameters for acquisition functions, solvers for them and anything related;
an object `plc` of type Policy is callable, run `plc(dsm::DecisionSupportModel)` to get
the next observation locations;
an advanced policy can set a flag `is_finished` in a DSM to stop optmization - when the cost of
acquiring a new point outweights the information gain
"""
abstract type Policy end

include("OptimizationHelper.jl")
include("DecisionSupportModels/Turbo/Turbo.jl")
include("Policies/TurboPolicy.jl")
include("utils.jl")

"""
perform initial sampling of f
"""
function initialize!(dsm::DecisionSupportModel, oh::OptimizationHelper, f) end

"""
return the next observation locations
"""
function ask(dsm::DecisionSupportModel, plc::Policy, oh::OptimizationHelper)
    # callable object `plc` is a good use-case for multiple dispatch - we use it to specify
    # the interaction between a specific dsm type and a specific policy type
    xs = plc(dsm)
    log_ask!(oh, xs)
    xs
end

"""
trigger an update of the decision suport model to incorporate new observations
`ys` at locations `xs`
"""
function tell!(dsm::DecisionSupportModel,
               oh::OptimizationHelper,
               xs::Vector{Float64},
               ys::Vector{Float64})
    update!(dsm, oh, xs, ys)
    # TODO: update observed_optimum in oh, append xs, ys to history
    # log_tell!(oh, xs, ys)
end

"""
run optimization loop until the is_finished flag in decision support model is set to true
"""
function optimize!(dsm::DecisionSupportModel, plc::Policy, oh::OptimizationHelper, f)
    while !dsm.isdone # TODO: and duration <= maxduration via oh
        # apply policy
        xs = ask(dsm, plc, oh)
        ys = eval_fun(oh, f, xs)
        # trigger update of the decision supp. model
        tell!(dsm, oh, xs, ys)
    end
end

end # module
