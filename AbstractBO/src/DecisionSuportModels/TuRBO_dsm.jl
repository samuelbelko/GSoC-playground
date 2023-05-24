"""
a generalization of TuRBO with arbitrary surrogates
"""
abstract type TuRBO_dsm <: DecisionSupportModel end

"""
TuRBO with GPs as surrogates
"""
mutable struct TuRBO_GPs_dsm <: TuRBO_dsm
    # save state: TR sizes, locations, sucess and failure counters etc.
end
