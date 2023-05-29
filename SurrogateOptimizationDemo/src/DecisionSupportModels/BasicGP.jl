"""
Basic BO with a GP
"""
mutable struct BasicGP <: DecisionSupportModel
    isdone
    # save state, maintain a GP model
end

function initialize!(dsm::BasicGP, mm::MetadataManager, f)

end

function update!(dsm, xs, ys)

end
