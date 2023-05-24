"""
a generalization of TuRBO with arbitrary surrogates of type T
"""
mutable struct TuRBO_dsm{T} <: DecisionSupportModel
    surrogates::Vector{T}
    is_finished
    # save state: TR sizes, locations, sucess and failure counters etc.
end

"""
initialize arbitrary TuRBO_dsm{T}
"""
function initialize!(dsm::TuRBO_dsm,mm::MetadataManager,f)

end

function add_observations!(dsm, xs, ys)

end
