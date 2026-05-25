# DFMethods.jl quick-reference (v0.3.2+)

Optional cheat-sheet for `/init-project` to reference when populating
`jcode/CLAUDE.md`'s DFMethods integration section. Read this only when
the user opts into DFMethods.jl at the NLE-path solver-framework
question.

For the full integration reference, see
`<toolkit>/guides/dfmethods-integration.md`.

## `DFProjection` keyword arguments

```julia
DFProjection(;
    direction       = SpectralThreeTerm(),        # AbstractSearchDirection
    linesearch      = ResidualNormBacktrack(),    # LineSearch.AbstractLineSearchAlgorithm
    inertial        = Inertial(0.25),             # AbstractInertialRule
    iterate_update  = SolodovSvaiterProjection(), # AbstractIterateUpdate
    callbacks       = AbstractCallback[],         # observer callbacks
    abstol          = 1e-6,
    maxiters        = 2000,
    stopping        = nothing,                    # builds AnyOf(AbsResidualTol, MaxIters) if nothing
    ζ               = 0.5,                        # approximate-projection tolerance factor
    inner_maxiter   = 500,                        # Dykstra inner iter cap
    maxbt           = 50,                         # line-search backtracks per iter
)
```

## Built-in components

### Search directions

- `SpectralThreeTerm(; r=0.1, alpha_bar=1.0, alpha_min=1e-10, alpha_max=1e30)` (default)

### Line searches (all `<: LineSearch.AbstractLineSearchAlgorithm`)

- `ConstantBacktrack(; σ=0.01, ρ=0.6, maxbt=50)` — γ_k ≡ 1
- `ResidualNormBacktrack(; σ=0.01, ρ=0.6, maxbt=50)` — γ_k = ‖F(z)‖ (default)
- `AdaptiveClampedBacktrack(; σ=0.01, ρ=0.6, lo=1e-4, Δ_init=10.0, maxbt=50)` — γ_k = clamp(‖F(z)‖, lo, lo+Δ)

### Inertial rules

- `NoInertial()` — θ ≡ 0
- `Inertial(θ=0.25)` (default) — θ_k = min(θ, 1/(k²‖Δx‖))

### Iterate-update strategies

- `SolodovSvaiterProjection(; γ=1.0)` (default) — γ ∈ (0,2) relaxation factor; γ=1 preserves byte-identical pre-0.3.2 behavior; values in (1,2) (commonly 1.6–1.8) are over-relaxation.
- `DirectUpdate()` — `x_{k+1} = project(z, set)`.
- `HalpernUpdate(β)` — `x_{k+1} = β·x_0 + (1-β)·z`; β scalar or schedule `k -> Float64`.

## Built-in constraint sets

- `RealSpace()` — unconstrained
- `BoxSet(lb, ub)` — componentwise box; pass via `NonlinearProblem(F, x0; lb, ub)`
- `HalfSpace(a, c)` — single linear `a' x ≤ c`
- `CappedBox(a, b, c)` — box ∩ single linear (built-in fast path)
- `Intersection(X1, X2; maxiter=500, tol=1e-12)` — `X1 ∩ X2` via Dykstra
- `UserSet(proj!)` — anything else; user supplies in-place `project!(y, x, set)`

## Solver call shape

```julia
using DFMethods, SciMLBase

# Unconstrained:
sol = solve(NonlinearProblem(F, x0), DFProjection())

# Box-constrained via SciMLBase lb/ub:
sol = solve(NonlinearProblem(F, x0; lb, ub), DFProjection())

# Other convex sets:
sol = solve(ConstrainedNonlinearProblem(F, x0; set = HalfSpace([1.0, 1.0], 1.0)),
            DFProjection())
```

Returns `SciMLBase.NonlinearSolution`. The adapter at
`jcode/src/adapter.jl` bridges to the toolkit's `SolverResult`.

## Extension contracts (for `src/extras.jl`)

| Slot | Abstract type | Method to implement |
|---|---|---|
| Search direction | `DFMethods.AbstractSearchDirection` | `direction!(d, rule, ctx)` |
| Line search | `LineSearch.AbstractLineSearchAlgorithm` | `init(prob, alg, fu, u)` + `solve!(cache, u, du)` |
| Inertial rule | `DFMethods.AbstractInertialRule` | `inertial_coef(rule, k, xk, xkm1)` |
| Iterate update | `DFMethods.AbstractIterateUpdate` | `update_iterate!(x_new, rule, ctx)` |

See `DFMethods.jl/examples/*.jl` for canonical templates and
`<toolkit>/guides/dfmethods-integration.md` § 12 for the full pattern.

## Don't edit `DFMethods.jl`

The library ships from the Julia General registry. The project pins via
`[compat] DFMethods = "0.3.2"` (caret-style; allows 0.3.x patch updates).
Custom extensions live in `jcode/src/extras.jl`. If a feature is missing,
open an upstream issue at <https://github.com/mmogib/DFMethods.jl/issues>.
