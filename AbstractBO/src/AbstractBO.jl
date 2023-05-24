module AbstractBO

export ask, tell!, optimize # add some concrete types of subtypes DSMs and Policies

include("metadata_manager.jl")

"""
provide funtionalities for aggregation of observations into a decision model used in a policy,
maintain a state of the optimization process (e.g. Trust regions in TuRBO) and surrogates
"""
abstract type DecisionSupportModel end
"""
maintain parameters for acquisition functions, their optimizers and anything related
decide next observation locations based on an instance of a DecisionSupportModel,
an instance of policy `plc` is a callable object `plc(dsm::DecisionSupportModel)`
an advanced policy can set a flag `finished` in a DSM to stop optmization - when the cost of
acquiring a new point outweights the information gain
"""
abstract type Policy end

"""
perform initial sampling of f
"""
function initialize(dsm::DecisionSupportModel, mm::MetadataManager, f) end

"""
return the next observation location
"""
function ask(dsm::DecisionSupportModel, plc::Policy, mm::MetadataManager)
    # callable object `plc` is good for multiple dispatch
    xs = plc(dsm)
    log_ask!(mm, xs)
    xs
end

"""
trigger an update of the decision suport model to incorporate new observations
`ys` at locations `xs`
"""
function tell!(
    dsm::DecisionSupportModel,
    mm::MetadataManager,
    xs::Vector{Float64},
    ys::Vector{Float64},
)
    add_observations!(dsm, xs, ys)
    log_tell!(mm, xs, ys)
end

"""
log function evaluation times
"""
function eval_fun(mm::MetadataManager, f, xs)
    ## eval f and log time in mm
    return f.(xs)
end

"""
run optimization loop until the finished flag in decision support model is false
"""
function optimize(dsm::DecisionSupportModel, plc::Policy, mm::MetadataManager, f)
    while !dsm.finished
        # apply policy
        xs = ask(dsm, plc, mm)
        ys = eval_fun(mm, f, xs)
        # trigger update of the decision supp. model
        tell!(dsm, mm, xs, ys)
    end
end

end # module
