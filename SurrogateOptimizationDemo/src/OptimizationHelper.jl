"""
saves lowerbounds, upperbounds, number of init. samples, max iteration, max duration, etc.
saves history, current optimizaters,
prints stats based on verbose levels, plots performance
"""
mutable struct OptimizationHelper
    sense::Any
    verbosity::Any

    lb::Vector{Float64}
    ub::Vector{Float64}
    dim::Int

    # n_init::Int # number of initial samples
    # batch_size::Int

    evaluations::Any
    duration::Any
    max_evaluations::Int
    max_duration::Int

    hist_x::Vector{Float64}
    hist_fx::Vector{Float64}
    observed_optimum::Float64
    observed_optimizer::Vector{Float64}
end
# TODO: input checks in constructor

# Maybe Implement here, or directly where it is used:
function log_ask!(mm, xs) end
function log_tell!(mm, xs, ys) end
function log_eval!(mm, time) end
# pritty printing based on verbose levels
# get optimizers, stats, plots at any time (e.g. while using ask-tell interface)
