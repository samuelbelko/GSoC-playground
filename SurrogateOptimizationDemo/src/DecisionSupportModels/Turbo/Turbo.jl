include("TurboTR.jl")

"""
`TuRBO` with an arbitrary `AbstractSurrogate` local model.

We assume that the domain is [0,1]^dim and we are maximizing.

TODO: hyperparmeter optimization for GPs
TODO: it is not yet clear how it can work for an arbitrary `AbstractSurrogate`.
"""
mutable struct Turbo <: DecisionSupportModel
    # number of surrogates
    n_surrogates::Int
    batch_size::Int
    # mum of initial samples for each local model
    n_init_for_local::Int

    isdone::Bool
    surrogates::Vector{AbstractSurrogate}
    trs::Vector{TurboTR}
    # TODO: hyperparameters for each TR?
    # hyperparameters::Vector{Float64}

    # use these for constructing surrogates at initialization and init. after restarting a TR
    create_surrogate::Function
    # save TR options for use in initialize!(..) and in later restarts of TRs
    tr_options::NamedTuple
    # TODO: type of sobol seq ?
    sobol_generator::Any
end

function Turbo(n_surrogates, batch_size, n_init_for_local, dimension, create_surrogate;
               tr_options = (;))
    # create placeholders for surrogates and trs;
    # merge TR options with defaults from the paper
    # TODO: how to include default params specially for the GP model?
    #       - in the paper Matérn-5/2 kernel, constant mean, ARD with bounds on hyperparams.
    #         lengthscale λ_i in [0.005,2.0], signal variance s^2 in [0.05,20.0], noise var. σ^2 in [0.0005,0.1]
    # TODO: how many samples do we need to skip for Sobol for better uniformity?
    sobol_gen = SobolSeq(dimension)
    # skip first 2^10 -1 samples
    skip(sobol_gen, 10)
    Turbo(n_surrogates, batch_size, n_init_for_local, false,
          Vector{AbstractSurrogate}(undef, n_surrogates),
          Vector{TurboTR}(undef, n_surrogates),
          create_surrogate,
          merge_with_tr_defaults(tr_options, dimension, batch_size),
          sobol_gen)
end

function merge_with_tr_defaults(tr_options, dimension, batch_size)
    # TODO: Set failure_tolerance using max as def. in https://botorch.org/tutorials/turbo_1 ?
    # Default hyperparameters from the paper for domain rescaled to [0,1]^dim
    tr_defaults = (base_length = 0.8,
                   length_min = 2^(-7),
                   length_max = 1.6,
                   failure_counter = 0,
                   failure_tolerance = ceil(dimension / batch_size),
                   success_counter = 0,
                   success_tolerance = 3)
    @assert issubset(keys(tr_options), keys(tr_defaults))
    # values of tr_options overwrite values of tr_defaults
    merge(tr_defaults, tr_options)
end

function initialize!(dsm::Turbo, oh::OptimizationHelper)
    # TODO: check if evaluation budget is enough for evaluating initialization samples
    for i in 1:(dsm.n_surrogates)
        initialize_local!(dsm, oh, i)
    end
end

"""
Initialize i-th local model and its trust region.

We use it also for restarting a TR after its convergence.
"""
function initialize_local!(dsm::Turbo, oh::OptimizationHelper, i)
    # TODO: make initial sampler a parameter of Turbo
    # TODO: make it work for general domains (implement: from_unit_cube, to_unit_cube)
    # TODO: check if evaluation budget saved in oh is enough for running initialization_local!
    xs = [next!(dsm.sobol_generator) for _ in 1:(dsm.n_init_for_local)]
    ys = evaluate_objective!(oh, xs)

    dsm.surrogates[i] = dsm.create_surrogate(xs, ys)
    # set observed maximizer in a local model
    # TODO: in noisy observations, set center to max. of posterior mean
    observed_maximizer = center = xs[argmax(ys)]
    observed_maximum = maximum(ys)
    # TODO!!! : maintain lengthscales (and possibly other hyperparameters)
    #            or somehow get them via Surrogates.jl (AbstractGPs)
    # `lengths` not yet as in the paper
    lengths = dsm.tr_options.base_length .* ones(oh.dimension)
    lb, ub = compute_lb_ub(center, lengths)
    # merge two NamedTuples with disjoint keys
    dsm.trs[i] = TurboTR(merge(dsm.tr_options,
                               (lengths = lengths, center = center, lb = lb, ub = ub,
                                observed_maximizer = observed_maximizer,
                                observed_maximum = observed_maximum, tr_isdone = false))...)
end

"""
Process new evaluations `ys` at points `xs`, i.e, update local models and adapt trust regions.
"""
function update!(dsm::Turbo, oh::OptimizationHelper, xs, ys)
    @assert length(xs) == length(ys)

    for i in 1:(dsm.n_surrogates)
        # filter out points in trust region tr
        tr_xs = []
        tr_ys = []
        for (x, y) in zip(xs, ys)
            if in_tr(x, dsm.trs[i])
                push!(tr_xs, x)
                push!(tr_ys, y)
                # update corresponding local surrogate
                add_point!(dsm.surrogates[i], x, y)
            end
        end
        # update corresponding TR - counters, base_length, lengths, tr_isdone
        if !isempty(tr_xs)
            @assert !isempty(tr_ys)
            update_TR!(dsm.trs[i], tr_xs, tr_ys)
        end
        # restart TR if it converged
        if dsm.trs[i].tr_isdone
            println("restarting tr $(i)")
            initialize_local!(dsm, oh, i)
        end
        # TODO: maintain & optimize hyperparameters using log-marginal likelihood before
        #       proposing next batch,
        #       what to do for not GP local surrogates? (how to get lengthscales?)
        #         - maybe don't adjust them at all, use multiple dispatch for calling other method.
    end
end
