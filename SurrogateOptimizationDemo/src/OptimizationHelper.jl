"""
Saves optimization problem and logs progress.
"""
mutable struct OptimizationHelper
    # Objective f
    f::Function
    sense::Any
    # box constraints: lowerbounds, upperbounds
    lb::Vector{Float64}
    ub::Vector{Float64}

    verbosity::Any

    evaluation_counter::Any
    total_duration::Any
    max_evaluations::Int
    max_duration::Int

    hist_xs::Vector{Float64}
    hist_ys::Vector{Float64}
    observed_optimum::Float64
    observed_optimizer::Vector{Float64}
end
# TODO: checks inputs in constructor, e.g., @assert lb .<= ub

"""
Evaluate objective. Log number of function evaluations, total duration. Update
observed optimizer & optimal value. This is the only place where f is ever evaluated.
"""
function evaluate_objective!(oh::OptimizationHelper, xs)
    # TODO: increase evaluation counter, total duration time in oh
    # TODO: update observed optimizer
    (oh.f).(xs)
end

# TODO: printing based on verbose levels
