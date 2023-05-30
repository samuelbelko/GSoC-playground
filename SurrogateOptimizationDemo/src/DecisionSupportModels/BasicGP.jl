"""
Basic BO with a GP
"""
mutable struct BasicGP <: DecisionSupportModel
    isdone::Any
    # save state, maintain a GP model
end

function initialize!(dsm::BasicGP, oh::OptimizationHelper, f)
end

function update!(dsm, xs, ys)
end
