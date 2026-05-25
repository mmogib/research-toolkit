# adapter.jl — Bridge DFMethods to the benchmark harness.
#
# The library returns `SciMLBase.NonlinearSolution`. The harness's
# `SolverResult` has extra fields (cpu_time, flag in benchmark-style
# symbols, history) and is shaped for the SQLite schema. This file
# translates between the two.
#
# Convention: a wrapper takes `(F, set, x0; <DEFAULTS>..., eps, maxiter,
# track, callback) -> SolverResult` so any benchmark script can plug it
# in directly. `set` is an `AbstractConstraintSet` from DFMethods (CappedBox,
# BoxSet, HalfSpace, Intersection, RealSpace, UserSet).

# ============================================================================
# Generic adapter — wraps any DFProjection algorithm
# ============================================================================

"""
    solve_with_alg(F, set, x0, alg::DFProjection; eps, maxiter, track, callback)
        -> SolverResult

Generic adapter. Construct a problem from `(F, set, x0)`, hand off to
`solve(prob, alg; abstol, maxiters)`, and translate the
`NonlinearSolution` to a `SolverResult`.

- If `set isa RealSpace`: builds a plain `NonlinearProblem` (unconstrained).
- Otherwise: wraps in a `ConstrainedNonlinearProblem(inner, set)`.

`track` and `callback` are accepted for harness compatibility. Per-iter
history can be captured by adding a `HistoryCallback()` to `alg.callbacks`
directly when building `alg`; this adapter doesn't inject one for you.
"""
function solve_with_alg(F, set::AbstractConstraintSet,
                        x0::Vector{Float64}, alg::DFProjection;
                        eps::Float64 = 1e-6,
                        maxiter::Int = 2000,
                        track::Bool  = false,
                        callback     = nothing)
    f_2arg(u, p) = F(u)

    prob = if set isa RealSpace
        SciMLBase.NonlinearProblem(f_2arg, x0)
    else
        inner = SciMLBase.NonlinearProblem(f_2arg, x0)
        ConstrainedNonlinearProblem(inner, set)
    end

    t0  = time()
    sol = solve(prob, alg; abstol = eps, maxiters = maxiter)
    elapsed = time() - t0

    return SolverResult(
        SciMLBase.successful_retcode(sol.retcode),
        sol.stats.nsteps,
        sol.stats.nf,
        elapsed,
        sol.u,
        _retcode_to_flag(sol.retcode),
        IterRecord[],
    )
end

# ============================================================================
# Convenience: solve_uidfpaf — Ibrahim 2026 default configuration
# ============================================================================

const UIDFPAF_VERSION  = "2.0.0"   # v0.2 API
const UIDFPAF_DEFAULTS = (
    rho   = 0.6,
    sigma = 0.01,
    theta = 0.25,
    zeta  = 0.5,
    r     = 0.1,
)

"""
    solve_uidfpaf(F, set, x0; rho, sigma, theta, zeta, r, eps, maxiter, track, callback)
        -> SolverResult

Reference-default configuration: SpectralThreeTerm direction,
ResidualNormBacktrack line search, Inertial(θ) inertia,
SolodovSvaiterProjection iterate update. Thin wrapper over `solve_with_alg`.
"""
function solve_uidfpaf(F, set::AbstractConstraintSet, x0::Vector{Float64};
                       rho::Float64   = 0.6,
                       sigma::Float64 = 0.01,
                       theta::Float64 = 0.25,
                       zeta::Float64  = 0.5,
                       r::Float64     = 0.1,
                       eps::Float64   = 1e-6,
                       maxiter::Int   = 2000,
                       track::Bool    = false,
                       callback       = nothing)
    alg = DFProjection(;
        direction  = SpectralThreeTerm(; r = r),
        linesearch = ResidualNormBacktrack(; σ = sigma, ρ = rho),
        inertial   = Inertial(theta),
        ζ          = zeta,
        abstol     = eps,
        maxiters   = maxiter,
    )
    return solve_with_alg(F, set, x0, alg; eps = eps, maxiter = maxiter,
                                           track = track, callback = callback)
end

# ============================================================================
# Retcode translation: SciMLBase.ReturnCode.T → harness flag Symbol
# ============================================================================

"""
    _retcode_to_flag(rc::SciMLBase.ReturnCode.T) -> Symbol

Map a SciML return code to the benchmark harness flag convention
(`:converged`, `:maxiter`, `:stalled`, …).
"""
function _retcode_to_flag(rc::SciMLBase.ReturnCode.T)
    rc === SciMLBase.ReturnCode.Success    ? :converged         :
    rc === SciMLBase.ReturnCode.MaxIters   ? :maxiter           :
    rc === SciMLBase.ReturnCode.Stalled    ? :stalled           :
    rc === SciMLBase.ReturnCode.Failure    ? :linesearch_failed :
    rc === SciMLBase.ReturnCode.Terminated ? :terminated        :
    rc === SciMLBase.ReturnCode.Default    ? :default           :
    :unknown
end
