include("TurboTR.jl")

# TODO: here assuming domain is [0,1]^dim and that we are maximizing
"""
TuRBO with an arbitrary AbstractSurrogate local model.
"""
mutable struct Turbo <: DecisionSupportModel
    # number of surrogates
    n_surrogates::Int
    # mum of initial samples for each TR
    n_init_for_tr::Int

    isdone::Bool
    surrogates::Vector{AbstractSurrogate}
    trs::Vector{TurboTR}
    # save options for initialize!(..) and later restarts of TRs
    tr_options::NamedTuple
    # use these for construction of surrogates at init. and when restarting TRs
    surrogate_type::Type
    surrogate_args::Tuple
    surrogate_kwargs::NamedTuple
end

function Turbo(n_surrogates, tr_options, surrogate_type, surrogate_args, surrogate_kwargs)
    # create placeholders & merge with defaults
    Turbo(n_surrogates, false,
          Vector{AbstractSurrogate}(undef, n_surrogates),
          Vector{TurboTR}(undef, n_surrogates),
          merge_with_defaults(tr_options),
          surrogate_type, surrogate_args, surrogate_kwargs)
end

function merge_with_defaults(tr_options)
    # TODO: set failure_tolerance using max as def. in https://botorch.org/tutorials/turbo_1 ?
    # Default hyperparameters from the paper for domain rescaled to [0,1]^dim
    tr_defaults = (base_length = 0.8,
                   length_min = 2^(-7),
                   length_max = 1.6,
                   failure_counter = 0,
                   failure_tolerance = ceil(oh.dim / oh.batch_size),
                   success_counter = 0,
                   success_tolerance = 3)
    @assert issubset(keys(tr_options), keys(tr_defaults))
    # tr_options overwrite tr_defaults
    merge(tr_defaults, tr_options)
end

"""
Initialize Turbo - collect initial samples & fit local surrogates.
"""
function initialize!(dsm::Turbo, oh::OptimizationHelper, f)
    # TODO: check if evaluation budget is enough for initialization
    for i in 1:dsm.n_surrogates
        initialize_local!(dsm, oh, f, i)
    end
end

# Used also for restarts after convergence of trs
function initialize_local!(dsm::Turbo, oh::OptimizationHelper, f, i)
    # TODO: make initial sampler a parameter of Turbo, make it work for general domains
    # TODO: check if evaluation budget is enough for initialization_local
    xs = collect(ScaledSobolIterator(zeros(oh.dims), ones(oh.dims), dsm.n_init_for_tr))
    ys = eval_fun(oh, f, xs)

    dsm.surrogates[i] = create_surrogate(dsm::Turbo, xs, ys)

    observed_maximizer = center = xs[argmax(ys)]
    observed_maximum = maximum(ys)
    # TODO!!! : maintain lengthscales (and possibly other hyperparameters)
    #            or somehow get them via Surrogates.jl (AbstractGPs)
    lengths = repeat([tr_options.base_length], oh.dims)
    # merge of two NamedTuples with disjoint keys
    dsm.trs[i] = TurboTR(merge(tr_options,
                               (lengths = lengths,
                                center = center, observed_maximizer = observed_maximizer,
                                observed_maximum = observed_maximum, tr_isdone = false)))
end

# TODO: maybe intantiate dsm with this function istead of surrogate type, args, kwargs
function create_surrogate(dsm::Turbo, xs, ys)
    dsm.surrogate_type(xs, ys, dsm.surrogate_args...; dsm.surrogate_kwargs)
end

"""
Incorporate new observations `ys` at points `xs` into Turbo.
"""
function update!(dsm::Turbo, oh::OptimizationHelper, xs, ys)
    @assert length(xs) == length(ys)

    for (i, tr) in enumerate(dsm.trs)
        # filter out points in trust region tr
        tr_xs = []
        tr_ys = []
        for (x, y) in zip(xs, ys)
            if in_tr(x, tr)
                push!(tr_xs, x)
                push!(tr_ys, y)
                # update corresponding local surrogate
                add_point!(dsm.surrogates[i], x, y)
            end
        end
        # update corresponding TR - counters, base_length, lengths, tr_isdone
        update_TR!(tr, tr_xs, tr_ys)
        # restart TR
        if tr.tr_isdone
            initiate_local!(dsm,oh,f,i)
        end
    end
    # TODO: maintain & optimize hyperparameters,
    #       what to do for not GP local surrogates? (how to get lengthscales?)
end
