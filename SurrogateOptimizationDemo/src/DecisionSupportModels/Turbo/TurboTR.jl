"""
Maintain the state of one trust region.
"""
mutable struct TurboTR
    # base side length of a hyperrectangle trust region
    base_length::Float64
    length_min::Float64
    length_max::Float64
    failure_counter::Int
    failure_tolerance::Int
    success_counter::Int
    success_tolerance::Int
    # lengths for each dim are rescaled wrt lengthscales in fitted GP while maintaining
    # volume (base_length)^dim
    lengths::Vector{Float64}
    center::Vector{Float64}
    lb::Vector{Float64}
    ub::Vector{Float64}
    observed_maximizer::Vector{Float64}
    observed_maximum::Float64
    tr_isdone::Bool
end

function in_tr(x, tr::TurboTR)
    all(tr.lb .<= x .<= tr.ub)
end

function compute_lb_ub(center, lengths)
    # intersection of TR with [0,1]^dim
    lb = max.(0, min.(center .- 1 / 2 .* lengths, 1))
    ub = max.(0, min.(center .+ 1 / 2 .* lengths, 1))
    lb, ub
end

function compute_lengths(base_length, lengthscales)
    # TODO: more stable as in https://github.com/uber-research/TuRBO/blob/de0db39f481d9505bb3610b7b7aa0ebf7702e4a5/turbo/turbo_1.py#L184
    dimension = length(lengthscales)
    lengthscales .* base_length ./ prod(lengthscales)^(1 / dimension)
end

"""
Update TR state - success and failure counters, base_length, lengths, tr_isdone.
"""
function update_TR!(tr::TurboTR, tr_xs, tr_ys, lengthscales)
    @assert length(tr_xs) == length(tr_ys)
    # assert that xs are from curent TR? What if tr_xs = []?
    # TODO: add some epsilon to RHS like in (https://botorch.org/tutorials/turbo_1) ?
    batch_max = maximum(tr_ys)
    if batch_max > tr.observed_maximum
        # "success"
        tr.success_counter += 1
        tr.failure_counter = 0
        # TODO: set tr_center to max posterior mean in case of noisy observations?
        tr.center = tr.observed_maximizer = tr_xs[argmax(tr_ys)]
        tr.observed_maximum = batch_max
    else
        # "failure"
        tr.success_counter = 0
        tr.failure_counter += length(tr_xs)
    end
    # update trust region base_length
    if tr.success_counter == tr.success_tolerance
        # expand TR
        tr.base_length = min(2.0 * tr.base_length, tr.length_max)
        tr.success_counter = 0
    elseif tr.failure_counter >= tr.failure_tolerance
        # shrink TR
        tr.base_length /= 2.0
        tr.failure_counter = 0
    end
    # check for convergence, if we are done, we don't need to update lengths anymore
    if tr.base_length < tr.length_min
        tr.tr_isdone = true
    else
        # update lengths wrt updated lengthscales
        tr.lengths = compute_lengths(tr.base_length, lengthscales)
        tr.lb, tr.ub = compute_lb_ub(tr.center, tr.lengths)
    end
end
