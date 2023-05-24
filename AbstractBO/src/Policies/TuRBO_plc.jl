"""
TuRBO policy that works for abitrary TuRBO subtype
"""
mutable struct TuRBO_plc
    # maintain state and settings regarding the acquisition functions
end

# note: policies are callable objects
function (t_plc::TuRBO_plc)(t_dcm::TuRBO)
    # use t_dcm for sampling etc...
end
