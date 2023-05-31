"""
A policy from TuRBO algorithm for deciding where to sample next.

TODO: if we cannot implement it generally for all types of local surrogates,
     we can consider TuRBO{T} and constraint T to some abstract type
"""
mutable struct TurboPolicy
    # maintain state and settings regarding the acquisition functions
    # for each TR we use candidate_size many samples in a TS
    candidate_size::Int
end

function TurboPolicy(dimension, candidate_size = nothing)
    # default value from the TuRBO paper
    candidate_size_default = min(100 * dimension, 5000)
    candidate_size = candidate_size == nothing ? candidate_size_default : candidate_size
    TurboPolicy(candidate_size)
end

# note: policies are callable objects
function (policy::TurboPolicy)(dcm::Turbo)
    # TODO: implement TS
    # use dcm for sampling etc...
end
