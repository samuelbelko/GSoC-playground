### Example use: TuRBO algorithm

Please see also `example-branin.jl` for a concrete example and docs in code.

1. define `create_surrogate(xs, ys, hh::GPHyperparameterHandler)` method for creating local surrogates using hyperparameters in `hh` and evaluation data `xs`, `ys`
2. define `create_hyperparameter_handler(init_xs, init_ys)` method for creating a `HyperparameterHandler` managing hyperparameters of a local surrogate; `init_xs`, `init_ys` are an initial sample used for instantiation of first hyperparameters
3. continue as in general case below, in step 2: use the above functions in instantiation of `Turbo` DecisionSupportModel & instantiate a `TurboPolicy` Policy

### Example use: general case

1. instantiate an OptimizationHelper `oh`
2. instantiate a DecisionSupportModel `dsm` and a compatible Policy `policy` (i.e. we can obtain next evaluation point via `policy(dsm)`), passing configuration parameters to constructors respectively
3. run `initialize!(dsm, oh)`
4. call `optimize!(dsm, policy, oh)`
5. obtain optimizer from `oh` and checkout other metadata there