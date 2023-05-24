"""
Basic BO with a GP
"""
mutable struct Basic_GP_dsm <: DecisionSupportModel
    is_finished
    # save state, maintain a GP model
end

function initialize!(dsm::Basic_GP_dsm, mm::MetadataManager, f)

end

function add_observations!(dsm, xs, ys)

end
