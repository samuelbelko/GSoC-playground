### Example use

Please see also `example-branin.jl` for a concrete example and docs in code.

1. define `create_surrogate(xs, ys, hh::GPHyperparameterHandler)` method for creating local surrogates using hyperparameters in `hh` and evaluation data `xs`, `ys`
2. define `create_hyperparameter_handler(init_xs, init_ys)` method for creating a `HyperparameterHandler` managing hyperparameters of a local surrogate; `init_xs`, `init_ys` are an initial sample used for instantiation of first hyperparameters
3. instantiate an OptimizationHelper `oh`
4. instantiate a DecisionSupportModel `dsm` and a compatible Policy `policy` (i.e. we can obtain next evaluation point via `policy(dsm)`), passing configuration parameters to constructors respectively
5. run `initialize!(dsm, oh)`
6. call `optimize!(dsm, policy, oh)`
7. obtain optimizer from `oh` and checkout other metadata there

### Internal interfaces

TODO: document what functionalities `dsm`, `policy(dsm)`, `AbstractSurrogate` have to support etc. (e.g. in `AbstractSurrogate` access to `x`, `y`)