module SurrogateOptimizationDemo

using Surrogates
using AbstractGPs # access to kernels
using SurrogatesAbstractGPs
import Sobol: SobolSeq

export initialize!, optimize!, Turbo, TurboPolicy # and some concrete subtypes of DSMs and Policies

"""
Maintain a state of the decision support model (e.g. trust regions and local surrogates in TuRBO).

Provide `update!(dsm::DecisionSupportModel, oh::OptimizationHelper, xs, ys)` for aggregation
of evaluations `ys` at points `xs` into a decision model.
TODO: what does a policy need from a dsm?
"""
abstract type DecisionSupportModel end
"""
Decide where we evaluate the objective function next based on information aggregated
in a decision support model.

In particular, take care of details regarding acquisition functions & solvers for them.
An object `policy` of type Policy is callable, run `policy(dsm::DecisionSupportModel)`
to get the next batch of points for evaluation.
A policy may set the flag `isdone` in a decision support model to true (when the cost of
acquiring a new point outweights the information gain).
"""
abstract type Policy end

include("OptimizationHelper.jl")
include("DecisionSupportModels/Turbo/Turbo.jl")
include("Policies/TurboPolicy.jl")
include("utils.jl")

"""
Generate initial sample points, evaluate f on them and process evaluations.
"""
function initialize!(dsm::DecisionSupportModel, oh::OptimizationHelper) end

"""
Run optimization loop.
"""
function optimize!(dsm::DecisionSupportModel, policy::Policy, oh::OptimizationHelper)
    while !dsm.isdone && oh.total_duration <= oh.max_duration &&
              oh.evaluation_counter <= oh.max_evaluations
        # apply policy
        xs = policy(dsm)
        ys = evaluate_objective!(oh, xs)
        # trigger update of the decision support model
        update!(dsm, oh, xs, ys)
    end
end

# Turbo needs to restart TR when the correspoding local model has converged - it is not
# very compatible with ask-tell interface. Probably also not necessary for the use-case
# of this algorihtm.
#
# """
# return the next observation locations
# """
# function ask(dsm::DecisionSupportModel, plc::Policy, oh::OptimizationHelper)
#     # callable object `plc` is a good use-case for multiple dispatch - we use it to specify
#     # the interaction between a specific dsm type and a specific policy type
#     xs = plc(dsm)
#     log_ask!(oh, xs)
#     xs
# end

# """
# trigger an update of the decision suport model to incorporate new observations
# `ys` at locations `xs`
# """
# function tell!(dsm::DecisionSupportModel,
#                oh::OptimizationHelper,
#                xs::Vector{Float64},
#                ys::Vector{Float64})
#     update!(dsm, oh, xs, ys)
#     # TODO: update observed_optimum in oh, append xs, ys to history
#     # log_tell!(oh, xs, ys)
# end

end # module
