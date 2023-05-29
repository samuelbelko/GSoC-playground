"""
Basic BO with a GP
"""
mutable struct BasicGP <: DecisionSupportModel
    isdone
    # save state, maintain a GP model
end

function initialize!(dsm::BasicGP, mm::MetadataManager, f)

end

function add_observations!(dsm, xs, ys)

end
