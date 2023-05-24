"""
TuRBO policy that is called for TuRBO_dsm{T} with abitrary T, if we cannot
implement in such a generality, maybe we can constraint T to be some subtype
of an abstract type collecting those, where such an implementation is possible
"""
mutable struct TuRBO_plc
    # maintain state and settings regarding the acquisition functions
end

# note: policies are callable objects
function (t_plc::TuRBO_plc)(t_dcm::TuRBO)
    # use t_dcm for sampling etc...
end
