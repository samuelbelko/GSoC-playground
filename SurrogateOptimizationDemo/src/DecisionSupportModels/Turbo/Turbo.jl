include("TurboTR.jl")

"""
`TuRBO` with an arbitrary `AbstractSurrogate` local model.
TODO: here assuming domain is [0,1]^dim and that we are maximizing
TODO: it is not yet clear how it can work for an arbitrary `AbstractSurrogate`.
"""
mutable struct Turbo <: DecisionSupportModel
    # number of surrogates
    n_surrogates::Int
    batch_size::Int
    # dimension of the domain
    # TODO: dimension can be computed from lowerbounds but these are stored in OptimizationHelper..
    dimension::Int
    # mum of initial samples for each local model
    n_init_for_local::Int

    isdone::Bool
    surrogates::Vector{AbstractSurrogate}
    trs::Vector{TurboTR}
    # use these for construction of surrogates at initialization and init. after restarting a TR
    surrogate_type::Type
    surrogate_args::Tuple
    surrogate_kwargs::NamedTuple
    # save TR options for use in initialize!(..) and in later restarts of TRs
    tr_options::NamedTuple
end

function Turbo(n_surrogates, batch_size, dim, surrogate_type, surrogate_args,
               surrogate_kwargs; tr_options = (;))
    surrogate_type <: AbstractSurrogate ||
        throw(ArgumentError("expecting surrogate_type to be a subtype of AbstractSurrogate"))
    # create placeholders for surrogates and trs;
    # merge TR options with defaults from the paper
    Turbo(n_surrogates, batch_size, dim, false,
          Vector{AbstractSurrogate}(undef, n_surrogates),
          Vector{TurboTR}(undef, n_surrogates),
          surrogate_type, surrogate_args, surrogate_kwargs,
          merge_with_tr_defaults(tr_options, dim, batch_size))
end

function merge_with_tr_defaults(tr_options, dim, batch_size)
    # TODO: Set failure_tolerance using max as def. in https://botorch.org/tutorials/turbo_1 ?
    # Default hyperparameters from the paper for domain rescaled to [0,1]^dim
    tr_defaults = (base_length = 0.8,
                   length_min = 2^(-7),
                   length_max = 1.6,
                   failure_counter = 0,
                   failure_tolerance = ceil(dim / batch_size),
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

We use it also for a restart of a TR after its convergence.
"""
function initialize_local!(dsm::Turbo, oh::OptimizationHelper, i)
    # TODO: make initial sampler a parameter of Turbo
    # TODO: make it work for general domains (implement: from_unit_cube, to_unit_cube)
    # TODO: check if evaluation budget saved in oh is enough for running initialization_local!
    xs = collect(ScaledSobolIterator(zeros(dsm.dimension), ones(dsm.dimension),
                                     dsm.n_init_for_local))
    ys = evaluate_objective!(oh, xs)

    dsm.surrogates[i] = create_surrogate(dsm, xs, ys)
    # observed maximizer in a local model
    observed_maximizer = center = xs[argmax(ys)]
    observed_maximum = maximum(ys)
    # TODO!!! : maintain lengthscales (and possibly other hyperparameters)
    #            or somehow get them via Surrogates.jl (AbstractGPs)
    lengths = repeat([tr_options.base_length], dsm.dimension)
    # merge of two NamedTuples with disjoint keys
    dsm.trs[i] = TurboTR(merge(tr_options,
                               (lengths = lengths,
                                center = center, observed_maximizer = observed_maximizer,
                                observed_maximum = observed_maximum, tr_isdone = false)))
end

# TODO: maybe intantiate dsm with this function istead of surrogate type, args, kwargs
function create_surrogate(dsm::Turbo, xs, ys)
    # surrogate_type is a subtype of AbstractSurrogate
    dsm.surrogate_type(xs, ys, dsm.surrogate_args...; dsm.surrogate_kwargs)
end

"""
Process new observations `ys` at points `xs`, i.e, update local models and adapt trust regions.
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
        # restart TR if it converged
        if tr.tr_isdone
            initiate_local!(dsm, oh, i)
        end
    end
    # TODO: maintain & optimize hyperparameters,
    #       what to do for not GP local surrogates? (how to get lengthscales?)
end
