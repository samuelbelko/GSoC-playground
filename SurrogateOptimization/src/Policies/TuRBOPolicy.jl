"""
TuRBO policy that is called for TuRBO{T} with abitrary T, if we cannot
implement in such a generality, maybe we can constraint T to be some subtype
of an abstract type collecting those, where such an implementation is possible
"""
mutable struct TuRBOPolicy
    # maintain state and settings regarding the acquisition functions
end

# note: policies are callable objects
function (t_plc::TuRBOPolicy)(t_dcm::TuRBO)
    # use t_dcm for sampling etc...
end
