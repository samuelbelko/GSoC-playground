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

    # lengths for each dim are rescaled wrt lengthscales in fitted GP
    # while maintaining volume (base_length)^dim
    lengths::Vector{Float64}
    center::Vector{Float64}
    lb::Vector{Float64}
    ub::Vector{Float64}

    observed_maximizer::Vector{Float64}
    observed_maximum::Float64

    tr_isdone::Bool
end

function in_tr(x, tr::TurboTR)
    tr.lb .<= x .<= tr.ub
end

function compute_lb_up(center, lengths)
    # intersection of TR with [0,1]^dim
    lb = max.(0, min.(tr.center .- 1 / 2 .* tr.lengths, 1))
    ub = max.(0, min.(tr.center .+ 1 / 2 .* tr.lengths, 1))
    lb, up
end

function update_TR!(tr::TurboTR, tr_xs, tr_ys)
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
        # TODO!!! : update lengths wrt updated lengthscales
        tr.lengths = repeat([tr_options.base_length], length(tr.lengths))
        tr.lb, tr.ub = compute_lb_up(tr.center, tr.lengths)
    end
end
