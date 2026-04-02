# types.jl — Core types for solver results and history tracking
#
# Defines the data structures that ALL solvers return and that the DB/CSV
# layer reads and writes. Keep types.jl and benchmark.jl in sync: if you
# add a field to SolverResult, add the corresponding DB column too.

# ============================================================================
# Solver Result
# ============================================================================

"""
    SolverResult

Returned by every solver. Common fields are required; add project-specific
fields below the marked line.

## Solver contract (see guides/coding-style.md)
Every solver function must:
  1. Return a `SolverResult`
  2. Accept `track::Bool=false` keyword (enable per-iteration history)
  3. Accept `callback=nothing` keyword (live progress updates)
     Callback signature: `callback(k::Int, metric::Float64, maxiter::Int)`
"""
struct SolverResult
    # ── Common fields (do not remove) ────────────────────────────────────
    converged::Bool
    iterations::Int
    f_evals::Int
    cpu_time::Float64
    x::Vector{Float64}          # final iterate
    flag::Symbol                # :converged, :maxiter, :linesearch_failed, :error, ...
    history::Vector{IterRecord} # empty if track=false

    # ── Project-specific fields (add below) ──────────────────────────────
    # residual::Float64          # e.g., ‖F(x)‖ for nonlinear equations
    # Fx::Vector{Float64}       # e.g., final F(x) value
    # psnr::Float64             # e.g., for image reconstruction
end

# ============================================================================
# Iteration Record (for per-iteration history tracking)
# ============================================================================

"""
    IterRecord

One row of per-iteration convergence data. Stored in `SolverResult.history`
and bulk-inserted into the `history` DB table when `track=true`.

Common fields are required; add project-specific tracking columns below.
"""
struct IterRecord
    # ── Common fields ────────────────────────────────────────────────────
    k::Int                      # iteration number
    f_evals::Int                # cumulative function evaluations
    elapsed::Float64            # cumulative wall-clock time (seconds)

    # ── Project-specific fields (add below) ──────────────────────────────
    # norm_Fk::Float64          # ‖F(x_k)‖
    # alpha_k::Float64          # step size
    # norm_dk::Float64          # ‖d_k‖
    # bt_steps::Int             # backtracking steps in line search
end

# ============================================================================
# Constructors
# ============================================================================

"""
    make_result(; converged, iterations, f_evals, cpu_time, x, flag, history=[])

Keyword constructor for `SolverResult`. Use in error/catch paths to create
a failed result without running the solver:

    catch ex
        result = make_result(converged=false, iterations=0, f_evals=0,
                             cpu_time=0.0, x=copy(x0), flag=:error)
    end
"""
function make_result(;
        converged::Bool,
        iterations::Int,
        f_evals::Int,
        cpu_time::Float64,
        x::Vector{Float64},
        flag::Symbol,
        history::Vector{IterRecord} = IterRecord[],
        # ── Project-specific keyword args (add below) ────────────────────
        # residual::Float64 = NaN,
    )
    return SolverResult(
        converged, iterations, f_evals, cpu_time, x, flag, history,
        # residual,   # uncomment when field is added to struct
    )
end

# ============================================================================
# Solver Version Constants (declare in each solver file)
# ============================================================================
#
# Every solver file must declare these two constants:
#
#   const {SOLVER}_VERSION  = "1.0.0"
#   const {SOLVER}_DEFAULTS = (param1=val1, param2=val2, ...)
#
# VERSION follows semver: bug fix → PATCH, logic change → MINOR.
# DEFAULTS is the NamedTuple that is both hashed AND splatted to the solver.
# Changing defaults does NOT require a version bump (params are in the hash).
#
# Example:
#   const MYALGO_VERSION  = "1.0.0"
#   const MYALGO_DEFAULTS = (alpha=0.5, beta=0.1, gamma=1.8)
