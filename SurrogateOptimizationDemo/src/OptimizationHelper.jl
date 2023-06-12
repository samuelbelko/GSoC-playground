"""
Saves optimization problem and logs progress.
"""
mutable struct OptimizationHelper
    # Objective f
    f::Function
    # TODO: dimension can be computed from lowerbounds
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
    observed_optimum::Float64
    observed_optimizer::Vector{Float64}
end

# TODO: checks inputs in constructor
function OptimizationHelper(g, dimension, sense, lb, ub, max_evaluations)
    @assert all(lb .<= ub)
    # Preprocessing: rescale domain to [0,1]^dim, make it a maximization problem
    f(x) = Int(sense) * g(from_unit_cube(x, lb, ub))

    OptimizationHelper(f, dimension, sense, lb, ub, 0, max_evaluations,
                       Vector{Vector{Float64}}(),
                       Vector{Float64}(), -Inf,
                       Vector{Float64}(undef, dimension))
end

"""
Evaluate objective. Log number of function evaluations, total duration. Update
observed optimizer & optimal value. This is the only place where f is ever evaluated.
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

function get_hist(oh::OptimizationHelper)
    # rescale from unit cube to lb, ub
    [from_unit_cube(x, oh.lb, oh.ub) for x in oh.hist_xs], oh.hist_ys
end

function get_solution(oh::OptimizationHelper)
    from_unit_cube(oh.observed_optimizer, oh.lb, oh.ub), Int(oh.sense) * oh.observed_optimum
end
