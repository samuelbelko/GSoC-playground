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
    # hyperparameters corresponding to local surrogates
    hyperparameter_handlers::Vector{HyperparameterHandler}

    # use these for constructing surrogates at initialization and init. after restarting a TR
    create_surrogate::Function
    create_hyperparameter_handler::Function
    # save TR options for use in initialize!(..) and in later restarts of TRs
    tr_options::NamedTuple
    # TODO: type of sobol seq ?
    sobol_generator::Any
end

function Turbo(n_surrogates, batch_size, n_init_for_local, dimension, create_surrogate,
               create_hyperparameter_handler; tr_options = (;))
    # create placeholders for surrogates and trs;
    # merge TR options with defaults from the paper
    # TODO: how many samples do we need to skip for Sobol for better uniformity?
    sobol_gen = SobolSeq(dimension)
    # skip first 2^10 -1 samples
    skip(sobol_gen, 10)
    Turbo(n_surrogates, batch_size, n_init_for_local, false,
          Vector{AbstractSurrogate}(undef, n_surrogates),
          Vector{TurboTR}(undef, n_surrogates),
          Vector{HyperparameterHandler}(undef, n_surrogates),
          create_surrogate,
          create_hyperparameter_handler,
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
    # TODO: check if evaluation budget saved in oh is enough for running initialization_local!
    init_xs = [next!(dsm.sobol_generator) for _ in 1:(dsm.n_init_for_local)]
    init_ys = evaluate_objective!(oh, init_xs)
    # has to compute optimial hyperparameters from init_xs, init_ys here at inialization
    dsm.hyperparameter_handlers[i] = dsm.create_hyperparameter_handler(init_xs, init_ys)
    # use opt. hyperparmeters found on init_xs, init_ys
    dsm.surrogates[i] = dsm.create_surrogate(init_xs, init_ys,
                                             dsm.hyperparameter_handlers[i])
    # set center to observed maximizer in a local model
    # TODO: in noisy observations, set center to max. of posterior mean
    observed_maximizer = center = init_xs[argmax(init_ys)]
    observed_maximum = maximum(init_ys)
    # compute_lengths method from TurboTR.jl
    lengths = compute_lengths(dsm.tr_options.base_length,
                              get_lengthscales(dsm.hyperparameter_handlers[i]))
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
        # filter out points in the i-th trust region
        tr_xs = []
        tr_ys = []
        for (x, y) in zip(xs, ys)
            if in_tr(x, dsm.trs[i])
                push!(tr_xs, x)
                push!(tr_ys, y)
            end
        end
        new_xs = append!(dsm.surrogates[i].x, tr_xs)
        new_ys = append!(dsm.surrogates[i].y, tr_ys)

        update_hyperparameters!(new_xs, new_ys, dsm.hyperparameter_handlers[i])
        # if we updated hyperparmeters, we need to fit a new local surrogate
        if dsm.hyperparameter_handlers[i].updated
            dsm.surrogates[i] = dsm.create_surrogate(new_xs, new_ys,
                                                     dsm.hyperparameter_handlers[i])
        else
            # else update existing local surrogate
            for (x, y) in zip(tr_xs, tr_ys)
                add_point!(dsm.surrogates[i], x, y)
            end
        end
        # update corresponding TR - counters, base_length, lengths, tr_isdone
        if !isempty(tr_xs)
            @assert !isempty(tr_ys)
            update_TR!(dsm.trs[i], tr_xs, tr_ys,
                       get_lengthscales(dsm.hyperparameter_handlers[i]))
        end
        # restart TR if it converged
        if dsm.trs[i].tr_isdone
            println("restarting tr $(i)")
            # initalize_local! performs hyperparamter optimization on initial sample
            initialize_local!(dsm, oh, i)
        end
    end
end
