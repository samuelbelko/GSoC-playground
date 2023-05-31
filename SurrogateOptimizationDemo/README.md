### Example use

1. instantiate an OptimizationHelper `oh`
2. instantiate a DecisionSupportModel `dsm` and a compatible Policy `policy` (i.e. we can obtain next observation location via `policy(dsm)`), passing configuration parameters to constructors respectively
3. run `initialize!(dsm, oh)`
4. call `optimize!(dsm, policy, oh)`
5. obtain optimizer from `oh` and checkout other metadata there
