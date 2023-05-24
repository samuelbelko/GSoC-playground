"""
a generalization of TuRBO with arbitrary surrogates
"""
abstract type TuRBO_dsm <: DecisionSupportModel end

"""
TuRBO with GPs as surrogates
"""
mutable struct TuRBO_GPs_dsm <: TuRBO_dsm
    is_finished
    # save state: TR sizes, locations, sucess and failure counters etc.
end

"""
initialize arbitrary TuRBO_dsm
"""
function initialize!(dsm::TuRBO_dsm,mm::MetadataManager,f)

end

function add_observations!(dsm, xs, ys)

end
