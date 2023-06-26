"""
Saves optimization problem and logs progress.

Internally, it transforms domain into a unit cube and makes it a maximization problem.
"""
mutable struct OptimizationHelper
    # Objective f
    f::Function
    dimension::Int
    # either -1 or 1, for maximization +1, for min. -1
    sense::Sense
    # box constraints: lowerbounds, upperbounds
    lb::Vector{Float64}
    ub::Vector{Float64}
    # TODO: verbosity, for now we print everything
    #verbosity::Any
    evaluation_counter::Int
    max_evaluations::Int
    # TODO: duration; for now don't measure time
    # total_duration::Any
    # max_duration::Int

    # TODO: use NTuples for points instead of vectors?
    # evaluations in the normalized domain in [0,1]^dim
    hist_xs::Vector{Vector{Float64}}
    hist_ys::Vector{Float64}
    observed_optimizer::Vector{Float64}
    observed_optimum::Float64
end

function OptimizationHelper(g, sense::Sense, lb, ub, max_evaluations)
    max_evaluations <= 0 && throw(ArgumentError("max_evaluations <= 0"))
    if length(lb) != length(ub) || ! all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    dimension = length(lb)
    # Preprocessing: rescale domain to [0,1]^dim, make it a maximization problem
    f(x) = Int(sense) * g(from_unit_cube(x, lb, ub))

    OptimizationHelper(f, dimension, sense, lb, ub, 0, max_evaluations,
                       Vector{Vector{Float64}}(),
                       Vector{Float64}(),
                       Vector{Float64}(undef, dimension),
                       -Inf)
end

"""
Evaluate objective. Log number of function evaluations & total duration.

Update observed optimizer & optimal value. This is the only place where f is ever evaluated.
"""
function evaluate_objective!(oh::OptimizationHelper, xs)
    # TODO: increase total duration time in oh
    oh.evaluation_counter += length(xs)
    append!(oh.hist_xs, xs)
    ys = (oh.f).(xs)
    append!(oh.hist_ys, ys)
    argmax_ys = argmax(ys)
    if oh.observed_optimum < ys[argmax_ys]
        oh.observed_optimum = ys[argmax_ys]
        oh.observed_optimizer = xs[argmax_ys]
        # TODO: printing based on verbose levels
        println("#Evaluations: $(oh.evaluation_counter); Best objective approx. $(round(oh.observed_optimum, digits=2))")
    end
    ys
end

"""
Retrieve points and corresponding objective values that were evaluated so far.
"""
function get_hist(oh::OptimizationHelper)
    # rescale from unit cube to lb, ub
    [from_unit_cube(x, oh.lb, oh.ub) for x in oh.hist_xs], oh.hist_ys
end

"""
Retrieve observed optimizer.
"""
function get_solution(oh::OptimizationHelper)
    from_unit_cube(oh.observed_optimizer, oh.lb, oh.ub), Int(oh.sense) *
                                                         oh.observed_optimum
end
