# Julia Coding Style Guide

Mohammed's Julia engineering patterns, extracted from two battle-tested codebases:
- **VOP-LineSearch/CondGVOP** (Style A — Module Package): 267 tests, 48 problems, 6 experiments
- **MISTDFPM** (Style B — Flat Include): 16 problems, multi-solver comparison, iterator protocol

## Choosing an Architecture

At project start, choose one of two coding architectures:

| | Style A — Module Package | Style B — Flat Include |
|---|---|---|
| Entry point | `using ModuleName` | `include("src/includes.jl")` |
| Namespace | Isolated module, explicit exports | Global (all functions visible after include) |
| Code wrapper | `module ModuleName ... end` | No wrapper; files concatenated via includes |
| Dependencies | `using` inside module | Central `deps.jl` file |
| Algorithm params | `Base.@kwdef` config structs | Struct constructor + preset system |
| Algorithm loop | Explicit while loop in function | Julia iterator protocol (`Base.iterate`) |
| Tests | `test/runtests.jl` with `@testset` | Smoke test scripts |
| Best for | Reusable libraries, multiple algorithms sharing types, namespace isolation | Rapid prototyping, single-algorithm, many variants, evolving research code |

## Language & Tooling
- **Language**: Julia (1.10+)
- **Solver stack**: JuMP + HiGHS (LP), JuMP + Ipopt (QP/NLP)
- **Set representations**: LazySets (Hyperrectangle, Ball2, HPolytope, VPolytope, custom subtypes)
- **Standard library**: LinearAlgebra, Printf, Random, Test, Dates, Statistics, SparseArrays
- **Plotting**: Plots.jl (PGFPlotsX backend for LaTeX-quality figures)
- **Progress**: ProgressMeter.jl (for long-running loops)
- **Data**: DataFrames + CSV (Style B), or manual CSV I/O (Style A)
- **Benchmarking**: BenchmarkProfiles.jl for Dolan-More performance profiles (Style B)
- Avoid heavy dependencies. Prefer standard library when possible.

---

## Style A — Module Package

### File Structure
```
src/
├── ModuleName.jl    # Main module file (includes + exports only)
├── types.jl         # All type definitions first
├── core_algo.jl     # Core algorithm implementation
├── helpers.jl       # Helper functions (line search, subproblems, etc.)
├── utils.jl         # General utilities
├── io_utils.jl      # I/O, logging, file export
└── problems.jl      # Test problem definitions (last)
```

### Main Module File Pattern
```julia
module ModuleName

using LinearAlgebra, Printf, Random
using JuMP, HiGHS
using LazySets

# Include in dependency order
include("types.jl")
include("scalarization.jl")
include("subproblem.jl")
include("linesearch.jl")
include("algorithm.jl")
include("utils.jl")
include("io_utils.jl")
include("problems.jl")

# Exports organized by category
export
    # Types
    MyConfig, MyResult, MyAbstractType,
    # Algorithm
    solve, solve_subproblem,
    # Utilities
    check_derivatives, setup_logging, teardown_logging,
    # Problems
    get_problem, list_problems

end # module
```

### Load Path (Scripts)
```julia
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using ModuleName
```

---

## Style B — Flat Include

### File Structure
```
src/
├── includes.jl          # Single entry point (includes all others in order)
├── deps.jl              # Central dependency management
├── algorithm.jl         # Main algorithm (struct + iterator protocol)
├── direction.jl         # Direction computation variants
├── linesearch.jl        # Line search variants
├── projection.jl        # Projection methods (exact + inexact)
├── problems.jl          # Test problem definitions
├── benchmark.jl         # Shared benchmarking utilities
└── reference_algo.jl    # Comparison algorithms (optional)
```

### Entry Point (`includes.jl`)
```julia
# includes.jl — Single entry point for all source files
# Usage: include("src/includes.jl") from scripts or REPL

include("deps.jl")
include("problems.jl")
include("direction.jl")
include("linesearch.jl")
include("projection.jl")
include("algorithm.jl")
include("benchmark.jl")
# include("reference_algo.jl")
```

### Centralized Dependencies (`deps.jl`)
```julia
# deps.jl — All shared dependencies in one place
using LinearAlgebra
using SparseArrays
using Printf
using LazySets
using Random
using DataFrames, CSV
using ProgressMeter
using Statistics
using Dates
```

Scripts add only script-specific packages:
```julia
include("../src/includes.jl")
using Plots              # Script-specific
using BenchmarkProfiles   # Script-specific
```

### Algorithm as Struct + Iterator Protocol
```julia
struct MyAlgorithm{TF,TC,TX}
    F::TF                    # Problem function (wrapped for eval counting)
    C::TC                    # Constraint set
    x0::TX                   # Initial point
    ε::Float64               # Convergence tolerance
    # ... algorithm parameters ...
    f_evals::Iterationcounter   # Mutable counter embedded in struct
    ls_tracker::LSTracker       # Line search statistics
end

# Julia iterator protocol
function Base.iterate(m::MyAlgorithm)
    # First iteration setup
    x = copy(m.x0)
    # ... initialize ...
    return (x, state)
end

function Base.iterate(m::MyAlgorithm, state)
    # Subsequent iterations
    # Return nothing when converged
    if converged
        return nothing
    end
    # ... compute next iterate ...
    return (x_next, new_state)
end

# Convenience solve function
function solve(m::MyAlgorithm; maxiter=10000, verbose=false)
    for (k, x) in enumerate(Iterators.take(m, maxiter))
        if verbose
            @printf("k=%d: ‖F(x)‖=%.6e\n", k-1, norm(m.F(x)))
        end
    end
    # ... return results ...
end
```

### Preset System (Named Parameter Bundles)
```julia
const ALGORITHM_PRESETS = Dict{Symbol,NamedTuple}(
    :default   => (;),                              # Best from LHS search
    :paper     => (; ε=1e-6, η=1.0, σ=0.1),        # Conservative
    :no_inertia => (; λ=0.0),                       # Ablation variant
    :scale_small => (; ε=1e-6, maxiter=5000),       # n ≤ 10k
    :scale_large => (; ε=1e-4, maxiter=20000),      # n ≥ 50k
)

# Outer constructor with preset merging
function MyAlgorithm(F, C; preset=:default, kwargs...)
    merged = merge(ALGORITHM_PRESETS[preset], NamedTuple(kwargs))
    _MyAlgorithm_inner(F, C; merged...)
end

# Usage:
solver = MyAlgorithm(F, C; preset=:paper)
solver = MyAlgorithm(F, C; preset=:paper, ε=1e-8)  # Override specific param
```

### Mutable Counters & Trackers
```julia
struct Iterationcounter
    count::Base.RefValue{Int}
end
Iterationcounter() = Iterationcounter(Ref(0))
increment(c::Iterationcounter) = (c.count[] += 1)
value(c::Iterationcounter) = c.count[]

# Wrap F to count evaluations automatically
f_counter = Iterationcounter()
F_counted = x -> (increment(f_counter); F(x))

mutable struct LSTracker
    backtracking_counts::Vector{Int}
    step_sizes::Vector{Float64}
end
```

### Multi-Solver Benchmarking
```julia
struct SolverConfig
    name::String
    kwargs::NamedTuple
    constructor::Any    # e.g., MyAlgorithm, ReferenceAlgo, etc.
end

struct BenchmarkResult
    config_name::String
    problem_name::String
    dimension::Int
    iterations::Int
    converged::Bool
    final_residual::Float64
    cpu_time::Float64
    f_evals::Int
end

function run_single(config::SolverConfig, prob::Problem; maxiter=10000)
    solver = config.constructor(prob.F, prob.C; config.kwargs...)
    # ... solve and return BenchmarkResult ...
end

function run_benchmark(configs, problems_by_dim; maxiter=10000)
    results = BenchmarkResult[]
    for (dim, probs) in problems_by_dim
        for prob in probs, cfg in configs
            push!(results, run_single(cfg, prob; maxiter))
        end
    end
    return DataFrame(results)
end
```

### Custom Constraint Sets
```julia
# Extend LazySets for project-specific sets
struct TriangleSet{T} <: LazySet{T}
    lower::Vector{T}
    β::T
end

struct BallBoxSet{T} <: LazySet{T}
    center::Vector{T}
    radius::T
    lower::Vector{T}
    upper::Vector{T}
end

# Implement required interface methods for projection
```

### Script ARGS Pattern (Style B variant)
```julia
function main(args)
    run_all = isempty(args) || "all" ∈ args

    if run_all || "small" ∈ args
        run_benchmark_small()
    end
    if run_all || "mid" ∈ args
        run_benchmark_mid()
    end
    if "latex" ∈ args || "summary" ∈ args
        post_process_from_csv()
    end
end

main(ARGS)
```

## Type Design

### Abstract Type Hierarchies
Use abstract types as dispatch targets. Concrete subtypes carry parameters.
```julia
abstract type BetaMethod end
struct SteepestDescent <: BetaMethod end
struct FletcherReeves <: BetaMethod end
struct HagerZhang <: BetaMethod
    η_param::Float64    # Per-method parameter
end
HagerZhang() = HagerZhang(0.01)  # Default constructor
```

### Config Structs
Use `Base.@kwdef` for named defaults. Mathematical notation in field names.
```julia
Base.@kwdef struct AlgorithmConfig
    σ₁::Float64 = 1e-4         # Sufficient decrease parameter
    δ::Float64 = 0.5            # Backtracking factor
    ε::Float64 = 1e-6           # Convergence tolerance
    maxiter::Int = 5000         # Maximum iterations
    max_ls::Int = 50            # Maximum line search steps
    verbose::Bool = false       # Print per-iteration output
    print_every::Int = 100      # Print frequency (when verbose=false)
end
```

Convenience constructors for common patterns:
```julia
function AlgorithmConfig(β::BetaMethod; kwargs...)
    AlgorithmConfig(; β_method=β, ls_type=default_ls_type(β), kwargs...)
end
```

### Result Structs
Unified result type across algorithm variants.
```julia
struct AlgorithmResult
    x::Vector{Float64}
    Fx::Vector{Float64}
    stationarity::Float64
    iterations::Int
    f_evals::Int
    g_evals::Int
    time_seconds::Float64       # Explicit units in field name
    status::Symbol              # :optimal, :maxiter, :linesearch_failed, :error
    algorithm::Symbol           # :condg, :nlcg, etc.
    history::Vector{HistoryEntry}
end
```

Backward-compatible aliases and accessors:
```julia
const OldResult = AlgorithmResult   # Alias for backward compat

function Base.getproperty(r::AlgorithmResult, s::Symbol)
    s === :v_val && return getfield(r, :stationarity)
    return getfield(r, s)
end
```

### Cone/Set Types
```julia
abstract type ConeType end
struct NonnegOrthant <: ConeType
    m::Int
end
struct GeneralCone <: ConeType
    generators::Matrix{Float64}  # Each column is a generator
    m::Int
end
```

## Multiple Dispatch

Use dispatch on abstract types for algorithm variants:
```julia
# Fast path for standard cone
function scalarize(φ::ODF, y::AbstractVector, C::NonnegOrthant)
    return maximum(y)
end

# General path
function scalarize(φ::ODF, y::AbstractVector, C::GeneralCone)
    # QP-based implementation
end
```

Function dispatch tables:
```julia
default_wolfe_type(::SteepestDescent) = StandardWolfe()
default_wolfe_type(::FletcherReeves) = StrongWolfe()
default_wolfe_type(::HagerZhang) = RestrictedWolfe()
```

## Naming Conventions

### Types
- **CamelCase**: `NonnegOrthant`, `GeneralCone`, `AlgorithmConfig`, `VOPResult`
- Mirror paper terminology: `NSF`, `ODF`, `CondG`, `NLCG`

### Functions
- **snake_case**: `solve_subproblem`, `nonmonotone_linesearch`, `compute_beta`, `check_derivatives`
- Internal helpers prefixed with underscore: `_fmax`, `_odf`, `_in_cone`

### Variables
- **Mathematical Greek**: `σ₁`, `δ`, `η_max`, `ε`, `φ`, `ξ`, `β`, `λ`, `τ`
- **Descriptive**: `f_evals`, `g_evals`, `time_seconds`, `start_type`

### Constants (in scripts)
- **UPPER_SNAKE**: `TUNED_σ1`, `N_STARTS`, `RNG_SEED`, `RAW_HEADER`, `SUMMARY_HEADER`

### Files
- **snake_case**: `types.jl`, `io_utils.jl`, `linesearch.jl`
- **Scripts**: `s{NN}_{description}.jl` (numbered in increments of 10)

### CSV Fields
- **snake_case**: `prob_id`, `prob_name`, `f_evals`, `v_final`, `time_s`, `success_rate`
- Abbreviated numeric suffixes: `F1`, `F2`, `F3` for multi-objective values

### Status Values
- **Symbols**: `:optimal`, `:maxiter`, `:linesearch_failed`, `:error`

## Closures for Problem Definitions

Store F and JF as closures (not module-level globals):
```julia
function get_problem(id::Int; kwargs...)
    if id == 15  # MOP1
        n, m = 2, 2
        F(x) = [x[1]^2, (x[1]-1)^2 + x[2]^2]
        JF(x) = [2x[1] 0.0; 2(x[1]-1) 2x[2]]
        K = Hyperrectangle(zeros(n), ones(n))
        x0 = [0.5, 0.5]
        return Problem(id, "MOP1", n, m, x0, K), F, JF
    end
    # ...
end
```

## Numerical Stability Patterns

### Guard Against Division by Zero
```julia
if abs(denominator) < 1e-30
    return 0.0  # Safe fallback
end
```

### Row Scaling for LP/QP Constraints
```julia
for i in 1:m
    row_scale = norm(JF[i, :])
    if row_scale > 1e-12
        # Scale constraint row
    end
end
```

### Fast Paths for Special Cases
```julia
# Analytical QP for m ≤ 10 (no external solver needed)
if m <= 10
    return analytical_steepest(JF)  # Active-set enumeration
else
    return ipopt_steepest(JF)       # JuMP + Ipopt
end
```

### NaN Handling in Statistics
```julia
if n_optimal > 0
    med_iters = median(iters_ok)
else
    med_iters = NaN   # Missing data → NaN, not error
end
```

## Error Handling

### Try-Catch with Detailed Logging
```julia
try
    result = solve(F, JF, x0; cfg=cfg)
    # Process result...
catch ex
    n_error += 1
    @printf(raw_io, "%d,%s,error,0,0,0,NaN,0.0,\n", id, name)
    flush(raw_io)
    @printf(logfile, "  [ERROR] prob %d, start %d: %s\n",
            id, start_idx, sprint(showerror, ex))
end
```

### Status-Based Flow (No Exceptions for Expected Outcomes)
```julia
if result.status == :optimal
    push!(iters_ok, result.iterations)
elseif result.status == :maxiter
    n_maxiter += 1
elseif result.status == :linesearch_failed
    n_lsfail += 1
end
```

## Testing Patterns

### Structure
```julia
@testset "ModuleName" begin
    @testset "Component A" begin
        @test result ≈ expected           # Floating-point: ≈
        @test result ≈ expected atol=1e-6 # Explicit tolerance
        @test exact_value == 42           # Integer: ==
        @test 0 <= val < 1               # Bounds
        @test all(isfinite.(vec))         # No NaN/Inf
    end
end
```

### Coverage Priorities
1. Mathematical primitives (RNG, cone operations, scalarization)
2. Problem loading and gradient correctness
3. Subproblem solvers
4. Full algorithm convergence on small problems

## Dependency Choices

| Package | Purpose | Rationale |
|---------|---------|-----------|
| JuMP | Algebraic modeling | Standard, flexible, solver-agnostic |
| HiGHS | LP solver | Open-source, fast, reliable |
| Ipopt | QP/NLP solver | Interior-point, handles nonlinear constraints |
| LazySets | Feasible sets | Type-stable representations, built-in operations |
| ProgressMeter | Progress bars | Lightweight, non-intrusive |
| Plots | Figures | PGFPlotsX backend for LaTeX quality |

Avoid heavy dependencies. Prefer standard library when possible (manual median over Distributions.jl).
