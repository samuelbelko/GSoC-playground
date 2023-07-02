## Notes on implementation

The main file `SurrogateOptimizationDemo.jl` contains the abstract optimization loop (evaluate policy that uses a decision support model to get a batch of points `xs`; evaluate objective ys = f.(xs), maintain stats; update decision support model; iterate).

The TuRBO algorithm is implemented as a `Turbo` decision support model with a compatible `TurboPolicy` policy.
All stats regarding optimization, e.g., function evaluation counter etc. are maintained in an `OptimizationHelper`. This can be used independently of the choice of a decision support model + policy.

For hyperparameter optimization of a general surrogate, we have an abstract type `HyperparameterHandler`. In Turbo algorithm, we maintain an array of those for each local surrogate in `Turbo`  decision support model. There is a concrete type `GPHyperparameterHandler` for hyperparameter tuning regarding to Gaussian processes (GPs) and `VoidHyperparameterHandler` that can be used to avoid hyperparameter optimization.

### Example use: TuRBO algorithm

Please see also `examples/branin.jl` for a concrete example and docs in code.

1. define `create_surrogate(xs, ys, hh::GPHyperparameterHandler)` method for creating local surrogates using hyperparameters in `hh` and evaluation data `xs`, `ys`
2. define `create_hyperparameter_handler(init_xs, init_ys)` method for creating a `HyperparameterHandler` managing hyperparameters of a local surrogate; `init_xs`, `init_ys` are an initial sample used for instantiation of first hyperparameters
3. continue as in general case below, in step 2: use the above functions in instantiation of `Turbo` DecisionSupportModel & instantiate a `TurboPolicy` Policy

### Example use: general case

1. instantiate an OptimizationHelper `oh`
2. instantiate a DecisionSupportModel `dsm` and a compatible Policy `policy` (i.e. we can obtain next evaluation point via `policy(dsm)`), passing configuration parameters to constructors respectively
3. run `initialize!(dsm, oh)`
4. call `optimize!(dsm, policy, oh)`
5. obtain optimizer from `oh` and checkout other metadata there