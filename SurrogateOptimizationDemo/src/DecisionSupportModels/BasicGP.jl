"""
TODO: Basic BO with a GP.
"""
mutable struct BasicGP <: DecisionSupportModel
    isdone::Bool
    # save state, maintain a GP model
end

function initialize!(dsm::BasicGP, oh::OptimizationHelper)
end

function update!(dsm::BasicGP, oh::OptimizationHelper, xs, ys)
end
