# DFMethods.jl integration

> When a project's `/init-project` flow selects the **NLE / NLSE** path
> and opts into **DFMethods.jl** at the solver-framework question, the
> toolkit scaffolds the adapter, callbacks, sweep helpers, problem
> registry, and `s01–s70` scripts in DFMethods-aware form. This guide
> is the single source of truth for the integration patterns those
> scaffolds use.
>
> DFMethods.jl is a configurable framework for derivative-free
> projection methods applied to constrained nonlinear monotone
> equations $F(x) = 0,\ x \in X \subset \mathbb{R}^n$. Library:
> <https://github.com/mmogib/DFMethods.jl>. Tutorial:
> <https://mmogib.github.io/DFMethods.jl/stable/tutorial/>.

## 1. Purpose & scope

This guide applies only when:

- `/init-project` Q1 = **Nonlinear System of Equations (NLE / NLSE)**, AND
- `/init-project` Q2 ∈ {**DFMethods.jl only**, **DFMethods.jl + bring-your-own solvers**} (the no-DFMethods variant uses generic `proj::Function` schema and skips the adapter / callbacks / sweep_helpers scaffolding).

It does not apply to:

- Projects in the **Something else** path (vector optimization, approximation, eigenvalue problems, …). Those projects use the toolkit's generic infrastructure with no DFMethods awareness.
- The DFMethods.jl library itself. The library is consumed via its registered public API; this guide is for *downstream* projects.

## 2. Library overview (v0.3.2)

`DFMethods.jl` exposes one concrete algorithm — `DFProjection` — composed of pluggable components:

| Slot | Built-in options |
|---|---|
| Search direction | `SpectralThreeTerm` (default) |
| Line search | `ConstantBacktrack`, `ResidualNormBacktrack` (default), `AdaptiveClampedBacktrack` |
| Inertial rule | `NoInertial`, `Inertial(θ=0.25)` (default) |
| Iterate update | `SolodovSvaiterProjection` (default; `γ ∈ (0,2)`), `DirectUpdate`, `HalpernUpdate(β)` |

The **constraint set is a property of the problem**, not the algorithm. Built-in sets: `RealSpace`, `BoxSet`, `HalfSpace`, `CappedBox`, `Intersection`, `UserSet`.

Solver call shape:

```julia
using DFMethods, SciMLBase

# Unconstrained:
prob = NonlinearProblem(F, x0)
sol  = solve(prob, DFProjection())

# Box-constrained via SciMLBase native lb/ub:
prob = NonlinearProblem(F, x0; lb = zeros(n), ub = fill(Inf, n))
sol  = solve(prob, DFProjection())

# Other convex sets via ConstrainedNonlinearProblem:
cprob = ConstrainedNonlinearProblem(F, x0; set = HalfSpace([1.0, 1.0], 1.0))
sol   = solve(cprob, DFProjection())
```

Returns a standard `SciMLBase.NonlinearSolution`. The adapter (§3) bridges it to the toolkit's canonical `SolverResult`.

Custom extensions (a new direction / line search / inertial rule / iterate-update strategy) subtype the relevant abstract type and implement the small `direction!` / `init` + `solve!` / `inertial_coef` + `apply_inertial!` / `update_iterate!` contract. See §12 and the canonical templates in `DFMethods.jl/examples/`.

## 3. Adapter boundary: `NonlinearSolution → SolverResult`

The adapter lives at `jcode/src/adapter.jl` (scaffolded at init time). Its only public function:

```julia
solve_with_alg(F, set, x0, alg::DFProjection;
               eps = 1e-6, maxiter = 2000,
               track = false, callback = nothing) -> SolverResult
```

Internally:

1. Builds `NonlinearProblem(F, x0)` if `set isa RealSpace`, else `ConstrainedNonlinearProblem(F, x0; set = set)`.
2. Calls `solve(prob, alg; abstol = eps, maxiters = maxiter)`.
3. Times the solve, maps `sol.retcode` to a toolkit `:flag` symbol via the table below, and returns a `SolverResult`.

### Retcode → flag mapping

| `sol.retcode` (DFMethods) | `SolverResult.flag` (toolkit) | Meaning |
|---|---|---|
| `Success` | `:converged` | `‖F(x*)‖ ≤ eps` |
| `MaxIters` | `:maxiter` | Hit iteration cap before tolerance |
| `MaxTime` | `:timeout` | Hit wall-clock cap before tolerance |
| `Stalled` | `:stalled` | Step-size or direction-norm fell below floor |
| `LineSearchFailed` | `:linesearch_failed` | Backtracking exceeded `maxbt` |
| `DegenerateResidual` | `:degenerate` | `‖F(z)‖ < eps(T)` mid-solve |
| (anything else) | `:error` | Unhandled retcode; check `sol.message` |

A `SolverResult` produced by the adapter always carries: `flag`, `x`, `residual = ‖F(x*)‖`, `iters`, `n_fevals`, `wall_time_s`, plus a `meta::Dict{Symbol,Any}` that holds the original `retcode` symbol and any history collected if `track = true`.

The adapter never throws — solver errors are caught and returned as `flag = :error` with the exception message in `meta[:error_message]`. This keeps the threaded sweep loop (§9) deadlock-free.

## 4. Constraint-set selection table

| Set | When to use | DFMethods constructor |
|---|---|---|
| `RealSpace` | Unconstrained ($X = \mathbb{R}^n$) | `RealSpace()` |
| `BoxSet` | Componentwise box constraints $\ell \le x \le u$ | `BoxSet(lb, ub)` or `NonlinearProblem(F, x0; lb, ub)` |
| `HalfSpace` | Single linear constraint $a^\top x \le c$ | `HalfSpace(a, c)` |
| `CappedBox` | Box ∩ single linear constraint (common in compressed sensing) | `CappedBox(lb, ub, a, c)` |
| `Intersection` | $X_1 \cap X_2$ for any two built-in sets | `Intersection(X1, X2; maxiter, tol)` |
| `UserSet` | Anything else; user provides `project!(y, x, set)` | `UserSet(proj!)` |

Inside `jcode/src/constraints_nle.jl`, the toolkit's canonical pattern groups constraint factories by name:

```julia
# Constraint constructors, parametric on problem dimension n.
const C_nonneg_orthant(n::Int)        = BoxSet(zeros(n), fill(Inf, n))
const C_unit_box(n::Int)              = BoxSet(zeros(n), ones(n))
const C_capped_box_unit(n::Int)       = CappedBox(zeros(n), ones(n), ones(n), 1.0)
const C_box_and_halfspace(n::Int)     = Intersection(BoxSet(-ones(n), ones(n)),
                                                     HalfSpace(ones(n), 1.0);
                                                     maxiter = 500, tol = 1e-12)
# ... etc
```

Add new constraint factories to the same file as your project grows. The `problems_nle.jl` registry references them by Julia symbol name (§5).

## 5. TestProblem registry pattern (single-file design)

`jcode/src/problems_nle.jl` holds everything related to NLE problem definitions: the `TestProblem` struct, the problem function implementations, the `PROBLEM_REGISTRY`, the `INITIAL_POINTS` recipes, and the lookup helpers. One file; no `_canonical` suffix split.

### `TestProblem` (unified struct, DFMethods + BYO)

```julia
struct TestProblem{F, SF}
    F::F                  # in-place F(out, x) or out-of-place F(x)
    set_factory::SF       # n::Int -> AbstractConstraintSet
    proj::Function        # for non-DFMethods solvers; auto-derived if only set_factory supplied
    reference::String     # bibliographic source
    fixed_n::Union{Nothing, Int}  # nothing = variable-n; or pinned dimension
    notes::String
end

# Convenience constructor: derive proj from set_factory via DFMethods.project
function TestProblem(F, set_factory; reference = "", fixed_n = nothing, notes = "")
    proj = (x) -> project(set_factory(length(x)), x)
    TestProblem(F, set_factory, proj, reference, fixed_n, notes)
end
```

`proj` is auto-derived from `set_factory` using `DFMethods.project` so non-DFMethods solvers (coexistence mode) can target the same problem with no extra wiring. A user who needs a non-standard `proj` (e.g., for a custom non-convex constraint) can override it explicitly.

### Registry + ordering

```julia
const PROBLEM_REGISTRY = Dict{Symbol, TestProblem}(
    :ExponentialI         => TestProblem(P01_ExponentialI, C_nonneg_orthant;
                                          reference = "Liu & Feng 2018, eq. 4.1",
                                          notes = "Smooth, monotone, separable"),
    :PolynomialI          => TestProblem(P02_PolynomialI, C_capped_box_unit;
                                          reference = "...", notes = "..."),
    # ... 28 entries when the canonical library is opted in.
)

const PROBLEM_ORDER = [:ExponentialI, :PolynomialI, ...]   # canonical paper order
const PROBLEM_IDS   = 1:length(PROBLEM_ORDER)
```

### Initial-point recipes

```julia
const INITIAL_POINTS = Dict{Symbol, Function}(
    :tenth          => (n) -> fill(0.1, n),
    :negativetenth  => (n) -> fill(-0.1, n),
    :allones        => (n) -> ones(n),
    :negativeones   => (n) -> -ones(n),
    :ntenthn        => (n) -> [i / (10n) for i in 1:n],
    :allzeros       => (n) -> zeros(n),
    # ... 17 entries in the canonical library
)
```

### Lookup helpers

```julia
get_problem(id::Int)         = PROBLEM_REGISTRY[PROBLEM_ORDER[id]]
get_problem(name::Symbol)    = PROBLEM_REGISTRY[name]
get_initial_points(n::Int, id::Int) -> Vector{Tuple{String, Vector{Float64}}}
```

`get_initial_points(n, id)` returns the labeled `x0` recipes for problem `id` at dimension `n`, respecting `prob.fixed_n` if set.

### Navigation comment block

The top of `problems_nle.jl` includes a registry table comment so a reader can scan the 28 problem → constraint mapping at a glance without scrolling through 28 docstrings. Generated by the skill at scaffold time:

```julia
# ════════════════════════════════════════════════════════════════════
#  Problem → constraint registry  (constraints in constraints_nle.jl)
# ────────────────────────────────────────────────────────────────────
#   P01_ExponentialI      →  C_nonneg_orthant
#   P02_PolynomialI       →  C_capped_box_unit
#   ...
# ════════════════════════════════════════════════════════════════════
```

## 6. Coexistence: DFMethods + bring-your-own solvers

When `/init-project` Q2 selects coexistence, the palette in `sweep_helpers.jl` carries a `solver_kind::Symbol` field per entry:

```julia
struct PaletteEntry
    label::String
    solver_kind::Symbol      # :dfmethods or :custom
    alg                       # for :dfmethods: a DFProjection; for :custom: a user callable
    params::NamedTuple        # hashed into config_hash
end
```

`run_sweep` dispatches on `entry.solver_kind`:

```julia
function _solve_one(entry::PaletteEntry, item::WorkItem)
    if entry.solver_kind == :dfmethods
        return solve_with_alg(item.prob.F, item.prob.set_factory(item.n), item.x0,
                              entry.alg; eps = entry.params.eps, maxiter = entry.params.maxiter)
    elseif entry.solver_kind == :custom
        return solve_with_custom(item.prob.F, item.prob.proj, item.x0,
                                  entry.alg; entry.params...)
    else
        error("unknown solver_kind: $(entry.solver_kind)")
    end
end
```

The user supplies `solve_with_custom` adapter for each non-DFMethods solver they want to compare against. Both adapters return `SolverResult` so the downstream DB schema, profiles, and tables are uniform.

The single-file `s30_benchmark.jl` runs both solver families through one palette and one `config_hash` space. `s70_figures.jl` produces combined performance profiles with no cross-script joins required.

## 7. Palette construction & config hashing

Palette construction happens at the top of `s30_benchmark.jl`, before the sweep loop:

```julia
function register_palette(db, cli)
    palette = PaletteEntry[]
    for label in cli[:methods]
        kind, alg, params = resolve_method(label, cli)
        push!(palette, PaletteEntry(label, kind, alg, params))
        config_hash = build_config_hash(label, params, cli)
        ensure_config!(db, config_hash, label, params)
    end
    return palette
end
```

`resolve_method(label, cli)` is project-specific — the user supplies the mapping from label strings (e.g., `"LSI"`, `"LSII"`, `"LSIII"`, …) to `(solver_kind, alg, params)` tuples. In DFMethods-only mode, all entries return `:dfmethods`; in coexistence mode, some entries may return `:custom`.

`build_config_hash(label, params, cli)` is **content-addressable**: same inputs → same hash → DB row skip on re-run. The hash inputs are:

- `label` (palette entry name)
- `params` NamedTuple (the *exact* set of fields used in `params`; do not include CLI flags that don't change the math)
- `cli[:eps]`, `cli[:maxiter]` (convergence criteria)
- `cli[:time_limit_s]` only if non-default (joins the hash only when set; preserves byte-identical hashes for pre-time-limit DB rows)

Treat the `params` NamedTuple as **simultaneously hashed and splatted** into the algorithm constructor — every field must be a hashable scalar (Float64, Int, Bool, Symbol). Functions, closures, and non-hashable types break determinism.

### Skip-by-default resume

```julia
worklist = WorkItem[]
for entry in palette, name in cli[:problems], n in cli[:dims], (init_label, x0) in get_initial_points(n, id)
    config_hash = build_config_hash(entry.label, entry.params, cli)
    push!(worklist, WorkItem(entry.label, config_hash, entry.alg, name, prob, n, init_label, x0))
end

existing = existing_set(db, worklist)              # set of (config_hash, problem, n, init) already in DB
filter!(item -> (item.config_hash, item.prob_name, item.n, item.init_name) ∉ existing, worklist)

if cli[:force]
    # ...re-run all items; --force overrides the skip filter
end
```

The DB primary key is `(config_hash, problem, dim, init_point)`. Re-running the same script without `--force` produces "Nothing to do" if all rows are already present.

## 8. Live progress: `ProgressUpdateCallback`

`jcode/src/callbacks.jl` defines:

```julia
mutable struct ProgressUpdateCallback{P, C} <: DFMethods.AbstractCallback
    prog::P                # ProgressMeter.Progress reference
    maxiter::Int
    counters::NamedTuple   # (:conv => Threads.Atomic{Int}, :fail => Threads.Atomic{Int})
    # per-solve mutable display fields (set by the sweep loop before each solve):
    ls_label::String
    prob_name::String
    n::Int
    init_name::String
end
```

The library fires `on_event!(cb, cache, event)` at four events. The callback responds at:

- **`:initialize`** — reads `cache.Fw` (initial residual) and updates the progress display once.
- **`:post_linesearch`** — reads `cache.Fz` (the post-line-search residual at the trial point) and updates the display each iter. **Load-bearing detail**: `cache.resid` is `NaN` mid-solve; `cache.Fz` is the only fresh residual at this event. Don't use `cache.resid` from inside this callback.

`Progress` is taken by reference (mutable wrapper), so the same callback instance is reused across palette entries — just rewrite the display fields between solves. Throttle the `ProgressMeter.update!` call to ~1 update per 200ms to keep terminal output readable on long solves.

### When threading is enabled

Under threading (`--threads N`, N ≥ 2), the callback is **not shared across worker tasks**. Each task builds its own `DFProjection` with a fresh `ProgressUpdateCallback` instance pointing at the same `Threads.Atomic{Int}` counters. The progress display is owned by the **writer task** (which also owns the SQLite handle); it updates the bar from atomic-counter reads, not from per-solve callbacks. See §9.

## 9. Threaded sweeps

`sweep_helpers.jl::run_sweep` dispatches on the `--threads` CLI flag:

- `--threads ≤ 1` → `_run_serial`: single-threaded loop; progress callback fires inside each solve.
- `--threads ≥ 2` → `_run_threaded`: producer/consumer with `Channel{WorkItem}` + N `Threads.@spawn` workers + 1 writer task.

### Threaded architecture

```
WorkItem queue (Channel{WorkItem})
     │
     ├──> Worker 1: pops items, builds alg, calls solve_with_alg, pushes SolverResult
     ├──> Worker 2: ...
     ├──> ...
     └──> Worker N: ...
                  ↓
            Result channel (Channel{Tuple{WorkItem, SolverResult}})
                  ↓
        Writer task: pops, calls insert_result!, updates progress, increments atomic counters
                  ↓
            SQLite DB (owned by writer task only — no shared handle)
```

Key invariants:

1. **Per-task alg rebuild** — each worker constructs its own `DFProjection` instance (via the palette entry's params); never share `alg` references across tasks.
2. **No shared SQLite handle** — only the writer task touches the DB. Workers produce; writer consumes.
3. **No shared callback** — workers don't fire `ProgressUpdateCallback`; the writer task updates progress from atomic counters.
4. **Solver errors are absorbed in the worker's `try/catch`** — converted to `flag = :error` `SolverResult` instances and pushed normally. This is critical: if a worker raises, the channel deadlocks. The adapter (§3) catches throws inside; the worker `try/catch` is a defense-in-depth second layer.

### Launching Julia with threads

```bash
julia -t <N+1> --project=. scripts/s30_benchmark.jl --threads <N>
```

Use `-t (N+1)` (one Julia thread per worker, plus one for the writer task). The script warns if you launched Julia with `Threads.nthreads() ≤ cli[:threads]`.

## 10. Recovery sweeps (`s40_recovery.jl`)

`s40_recovery.jl` re-runs items that failed under a reference sweep, with relaxed criteria. Default behavior: query the DB for items where `flag ∉ {:converged}` under the reference `(eps, maxiter)`, re-run them with `maxiter = 100_000` and `time_limit_s = 300.0`, and report a recovery summary.

CLI shape:

```
--target=failures        # default: only re-run prior failures
--target=all             # re-run the entire prior scope
--ref-eps=1e-6           # the eps the previous sweep used
--ref-maxiter=2000       # the maxiter the previous sweep used
--maxiter=100000         # recovery iter cap
--time-limit=300.0       # recovery wall-clock cap (seconds)
--dims=N,N,N             # restrict variable-n; fixed-n problems always at native dim
```

Recovery summary table at the end (computed via SQL self-join of new sweep rows × old sweep rows on `(problem, dim, init_point)` with different `config_hash`):

```
Method | Prev failed | Recovered | Still failed | Recovery %
LSI    | 12          | 9         | 3            | 75.0
LSII   | 18          | 14        | 4            | 77.8
...
```

The recovery sweep's `config_hash` differs from the reference sweep's (different `maxiter`, different `time_limit_s`), so both rows coexist in the DB without primary-key collision.

## 11. Figures (`s70_figures_tables.jl`)

`s70_figures_tables.jl` produces **Dolan–Moré performance profiles** from the DB. Three figures per metric, written to `results/figures/`:

- `fig_iters.{png,pdf}` — iterations to convergence
- `fig_fevals.{png,pdf}` — total function evaluations
- `fig_cpu.{png,pdf}` — CPU time

Failed solves contribute `Inf` to the metric (standard Dolan–Moré convention).

### `BenchmarkProfiles.jl` workaround

The high-level call

```julia
performance_profile(PlotsBackend(), T, labels; linestyles = [...], colors = [...])
```

collapses per-series kwargs in the GR backend (only one style is honored across all series). The toolkit's `s70_figures_tables.jl` template uses the lower-level path instead:

```julia
data = performance_profile_data(T)        # returns (τs, ys) per series
plot(; xscale = :log2, ...)
for (i, label) in enumerate(labels)
    plot!(data[1][i], data[2][i]; seriestype = :steppost,
          color = colors[i], marker = markers[i],
          linestyle = linestyles[i], label = label)
end
# Empty proxy series for legend markers (GR :steppost doesn't render markers in legend swatches):
for (i, label) in enumerate(labels)
    plot!([NaN], [NaN]; seriestype = :line, color = colors[i],
          marker = markers[i], label = label, primary = false)
end
```

This produces correct per-series color × marker × linestyle distinct legends.

### `log2` x-axis with integer labels

```julia
plot!(; xscale = :log2,
       xticks = (2.0 .^ (0:11), string.(0:11)))
```

Renders ticks at `2⁰, 2¹, …, 2¹¹` with the *exponents* `0, 1, …, 11` as labels (matches the paper convention).

## 12. Don't edit `DFMethods.jl` itself

The library ships from the Julia General registry at the version pinned in `Project.toml` (`[compat] DFMethods = "0.3.2"`). The project does not vendor it; bug-fixes and new features land upstream and arrive via `Pkg.update`.

Custom extensions (a new direction / line search / inertial rule / iterate-update strategy) live in **`jcode/src/extras.jl`** — scaffolded as an empty file with a comment block at init time when DFMethods is opted in. The four extension contracts:

```julia
# 1. Custom search direction
struct MyDirection <: DFMethods.AbstractSearchDirection
    # parameters
end
DFMethods.init_state(::MyDirection, prob, x, alg) = nothing  # or a mutable struct
function DFMethods.direction!(d, rule::MyDirection, ctx)
    # ctx fields: Fw, Fw_prev, w, w_prev, d_prev, k, α_prev, direction_state
    # write d in place; return d
end

# 2. Custom line search
struct MyLineSearch <: LineSearch.AbstractLineSearchAlgorithm
    # parameters
end
# Implement the CommonSolve.init / solve! contract.

# 3. Custom inertial rule
struct MyInertial <: DFMethods.AbstractInertialRule end
DFMethods.inertial_coef(rule::MyInertial, k, xk, xkm1) = 0.5

# 4. Custom iterate-update strategy
struct MyIterateUpdate <: DFMethods.AbstractIterateUpdate end
DFMethods.init_state(::MyIterateUpdate, prob, x, alg) = nothing
function DFMethods.update_iterate!(x_new, rule::MyIterateUpdate, ctx)
    # ctx fields: w, d, α, z, Fw, Fz, set, k, ζ, inner_maxiter, state
    # write x_new in place; return x_new
end
```

Canonical worked examples live in the library's `examples/` directory:

- `examples/mprpl_direction.jl` — Modified Polak–Ribière–Polyak direction
- `examples/nonmonotone_armijo.jl` — non-monotone Armijo line search
- `examples/mann_iteration.jl` — Mann averaging iterate-update with per-solve state
- `examples/mainge_inertia.jl` — Maingé inertial rule
- `examples/l1_ball.jl` — $\ell_1$-ball constraint set (custom `UserSet`)

Each is a runnable file demonstrating one extension contract end-to-end. Copy as a template.

If a needed feature isn't expressible via the extension API, open an issue at <https://github.com/mmogib/DFMethods.jl/issues> rather than patching the library locally.

## 13. References

- **Library**: <https://github.com/mmogib/DFMethods.jl> (registered package; install via `Pkg.add("DFMethods")`)
- **Docs**: <https://mmogib.github.io/DFMethods.jl/stable/>
  - Tutorial: `docs/src/tutorial.md` — hands-on walkthrough with callbacks and a small comparative sweep
  - Algorithm: `docs/src/algorithm.md` — the generic 7-step `step!` pseudocode
  - Extending: `docs/src/extending.md` — full extension-contract reference
- **DOI** (Zenodo concept, tracks latest): <https://doi.org/10.5281/zenodo.20350220>
- **Citation**: `CITATION.cff` in the library repo; the BibTeX `@software{...}` block in the README is the canonical form
- **Source-of-truth integration example**: the user's `DFMethods-starter` repo (the canonical reference; mirrored into the templates this guide describes)
