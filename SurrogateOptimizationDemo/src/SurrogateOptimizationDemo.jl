module SurrogateOptimizationDemo

export ask, tell!, optimize!, BasicGP, TuRBO, TuRBOPolicy, f # and some concrete subtypes of DSMs and Policies


"""
provide funtionalities for aggregation of observations into a decision model used by a policy;
maintain a state of the optimization process (e.g. Trust regions in TuRBO) and surrogates
"""
abstract type DecisionSupportModel end
"""
maintain parameters for acquisition functions, solvers for them and anything related;
an object `plc` of type Policy is callable, run `plc(dsm::DecisionSupportModel)` to get
the next observation locations;
an advanced policy can set a flag `is_finished` in a DSM to stop optmization - when the cost of
acquiring a new point outweights the information gain
"""
abstract type Policy end

include("MetadataManager.jl")
include("DecisionSupportModels/TuRBO.jl")
include("Policies/TuRBOPolicy.jl")


"""
perform initial sampling of f
"""
function initialize!(dsm::DecisionSupportModel, mm::MetadataManager, f) end

"""
return the next observation locations
"""
function ask(dsm::DecisionSupportModel, plc::Policy, mm::MetadataManager)
    # callable object `plc` is a good use-case for multiple dispatch - we use it to specify
    # the interaction between a specific dsm type and a specific policy type
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
    update!(dsm, xs, ys)
    log_tell!(mm, xs, ys)
end

"""
log function evaluation times
"""
function eval_fun(mm::MetadataManager, f, xs)
    # eval f and log time in mm
    # time = ...
    log_eval!(mm, time)
    f.(xs)
end

"""
run optimization loop until the is_finished flag in decision support model is set to true
"""
function optimize!(dsm::DecisionSupportModel, plc::Policy, mm::MetadataManager, f)
    while !dsm.isdone
        # apply policy
        xs = ask(dsm, plc, mm)
        ys = eval_fun(mm, f, xs)
        # trigger update of the decision supp. model
        tell!(dsm, mm, xs, ys)
    end
end

end # module
