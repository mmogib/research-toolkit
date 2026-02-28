module ModuleName

# === Imports ===
using LinearAlgebra, Printf, Random
using JuMP, HiGHS
# using Ipopt       # Uncomment if QP/NLP needed
# using LazySets    # Uncomment if feasible sets needed

# === Includes (dependency order) ===
include("types.jl")
# include("core_algorithm.jl")
# include("subproblem.jl")
# include("linesearch.jl")
include("utils.jl")
include("io_utils.jl")
include("problems.jl")

# === Exports ===
export
    # Types
    AlgorithmConfig, AlgorithmResult,
    # Algorithm
    # solve, solve_subproblem,
    # Utilities
    check_derivatives, setup_logging, teardown_logging, TeeIO,
    # Problems
    get_problem, list_problems

end # module
