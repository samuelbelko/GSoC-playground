"""
a generalization of TuRBO with arbitrary surrogates of type T
"""
mutable struct TuRBO{T} <: DecisionSupportModel
    surrogates::Vector{T}
    isdone
    # save state: TR sizes, locations, sucess and failure counters etc.
end

"""
initialize arbitrary TuRBO{T}
"""
function initialize!(dsm::TuRBO,mm::MetadataManager,f)

end

function add_observations!(dsm, xs, ys)

end
