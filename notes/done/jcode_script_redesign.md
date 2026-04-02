# jcode Script Redesign — Templates, Scaffolding, and /jcode-script

**Date**: 2026-04-02
**Status**: IMPLEMENTED — All 5 phases complete (2026-04-02)

---

## 1. Problem Statement

The current toolkit templates (`script_benchmark.jl`, `script_figure.jl`) and the `/jcode-script` skill were designed around manual CSV I/O, opt-in `--resume`, and top-level code. Real projects (e.g., PHD_FTDFfNoSE) have evolved to use:

- SQLite with content-addressable config hashing
- Skip-by-default + `--force` override (inverted resume)
- Key-value CLI args (`--problems=P1,P5`, `--dims=10000`)
- `main()` function wrapping (Julia scoping)
- DB-backed figures AND LaTeX tables in one script
- Shared DB infrastructure (`benchmark.jl`) across scripts

The toolkit needs to catch up with this proven practice.

---

## 2. Decisions (Confirmed 2026-04-02)

### D1: SQLite is the default storage backend
- SQLite with `--export` CSV support is the default for all scripts that produce results.
- User can opt for CSV-only at scaffolding time.
- OAT/sensitivity results should also go into the same `experiments.db` with an appropriate schema/table. One DB file for all experiment data.
- **Rationale**: single file, atomic writes, queryable, resume-safe, content-addressable.

### D2: Script pipeline varies per project
- No fixed set of scripts. Common ones: smoke test, benchmark, figures+tables.
- OAT, LHS, ablation, application — included when the user selects them.
- `/jcode-script` asks the user what they need; numbering is the user's choice (toolkit suggests logical ordering as guidance, not enforcement).
- An "other/custom" option lets the user specify goal, content, and dependencies freely.

### D3: DB infrastructure (`benchmark.jl`) becomes a toolkit template
- Merge with existing templates, don't replace.
- Template provides: `open_db`, `make_config_hash`, `ensure_config!`, `is_done`, `insert_result!`, `insert_history!`, `export_results_csv`, `print_summary`.
- Minimal/common functionality out of the box — grows as the user's project evolves.
- Schema is project-specific (the template provides a starter schema that the user adapts).

### D4: `/init-project` sets up DB infrastructure at scaffolding time
- When creating a new project, `/init-project` asks: SQLite or CSV?
- If SQLite: creates `src/benchmark.jl` with the DB layer template.
- If CSV: creates `src/csv_utils.jl` with CSV I/O helpers (headers, append, resume-by-reading).
- Either way, `src/io_utils.jl` (TeeIO) is always created.

### D5: All scripts wrapped in `main()`
- Every generated script wraps its body in `function main() ... end` + `main()` at the bottom.
- **Rationale**: Julia's scoped variable rules in newer versions cause issues with top-level `for` loops + `if` blocks. Function wrapping avoids this entirely.

### D6: TeeIO logging is on by default for all scripts
- `setup_logging` / `teardown_logging` included unless the user explicitly opts out.
- Even figure scripts get logging (they already benefit from "Saved: path" messages going to a log).

### D7: s70 becomes "figures and tables"
- The script that generates publication outputs handles: performance profiles, convergence plots, and LaTeX tables.
- Which outputs to include depends on the project — `/jcode-script` asks.
- Template name: `script_figures_tables.jl` (or the user picks their own name).

### D8: `/jcode-script` revised workflow
- **Phase 1**: Context discovery (unchanged — read CLAUDE.md, scan scripts, check infrastructure).
- **Phase 2**: User questions (revised):
  1. **Script type**: smoke test, OAT sensitivity, parameter search (LHS), benchmark, figures+tables, application, custom.
  2. **Storage backend**: SQLite (default) or CSV. Only asked once per project (subsequent scripts inherit the choice).
  3. **CLI flags**: present the recommended flag set for the chosen script type (per D24). User toggles on/off and adds custom flags.
  4. **Scope/features**: context-dependent. For benchmark: which methods, dimensions, tracking. For figures+tables: which outputs (profiles, convergence, tables). For application: what domain, what metrics.
  5. **Dependencies**: handled automatically based on choices made above.
- **Phase 3**: Generate (revised):
  1. Infrastructure check (io_utils.jl, benchmark.jl or csv_utils.jl).
  2. Compose the script from updated blocks, including only the selected CLI flags.
  3. Wrap in `main()`.
  4. Verify imports, infrastructure, paths.

---

## 3. Gaps Identified (Current Toolkit vs. Real Practice)

### 3.1 Missing patterns (need new code blocks in script-patterns.md)
- [ ] Config hashing / content-addressable experiments
- [ ] Key-value CLI parsing (`--key=value` alongside boolean flags)
- [ ] `WorkItem` struct pattern for work list construction
- [ ] Solver callback for live progress updates
- [ ] Selective history tracking with filter config
- [ ] Performance profiles via BenchmarkProfiles.jl
- [ ] LaTeX table generation (bolding best values, multirow, tier-averaged)
- [ ] Multi-panel figures (Q-linear convergence panels, zoom insets)
- [ ] DB-backed summary mode (query + DataFrame vs. manual CSV parsing)
- [ ] Skip-by-default + `--force` override pattern (replacing opt-in `--resume`)

### 3.2 Patterns to update
- [ ] Resume support: rewrite to skip-by-default (DB: check `is_done`; CSV: check existing rows)
- [ ] Summary mode: add DB variant alongside CSV variant
- [ ] CSV I/O: keep as alternative, add `--export` pattern
- [ ] ARGS parsing: add key-value parsing block
- [ ] Main loop: add `main()` wrapping to all patterns

### 3.3 Templates to update/add
- [x] `script_benchmark.jl` — rewrite with SQLite, config hashing, WorkItem, skip-by-default
- [x] `script_figure.jl` → `script_figures_tables.jl` — rewrite with DB reads, profiles, tables
- [x] NEW: `benchmark_db_template.jl` — DB infrastructure (open_db, config hash, CRUD)
- [x] NEW: `script_smoke_test.jl` — simple multi-solver verification
- [x] NEW: `script_oat.jl` — OAT sensitivity with DB storage
- [x] NEW: `script_parameter_search.jl` — LHS search with DB storage
- [x] NEW: `types_template.jl` — SolverResult, IterRecord, make_result
- [x] NEW: `problems_nle_template.jl` — NLE problems + projections + starting points
- [x] NEW: `problems_cs_template.jl` — Compressed sensing starter
- [x] NEW: `problems_imgrec_template.jl` — Image restoration starter
- [x] Updated `includes_template.jl` — JCODE_ROOT, new include order
- [x] Updated `deps_template.jl` — SQLite, SHA, DBInterface, JSON3

### 3.4 Skills to update
- [x] `/jcode-script` — revised workflow: type, storage, CLI flags, scope, dependencies
- [x] `/init-project` — DB scaffolding, domain checklist, types.jl, smoke test
- [x] `/optimization-research-workflow` — updated structure, key patterns, references

### 3.5 Guides to update
- [x] `guides/script-patterns.md` — added blocks 23-28 (config hash, WorkItem, callback, profiles, tables, starting points), updated blocks 1, 2, 3, 9, 10, 21
- [x] `guides/coding-style.md` — added solver interface contract section after Result Structs
- [x] `guides/experiment-workflow.md` — updated phases 0, 4, 5, 6, 7, 8 for DB-backed pipeline

---

## 4. Implementation Plan

### Phase 1: Core types and infrastructure templates
1. Write `templates/types.jl` — SolverResult, IterRecord, make_result (D10, D19)
2. Write `templates/benchmark_db.jl` — DB infrastructure: open_db, schema, config hash, CRUD (D3, D9)
3. Write `templates/problems_nle.jl` — nonlinear equations: Problem struct, get_problem, starting points, projections (D12, D20, D23)
4. Write `templates/problems_cs.jl` — compressed sensing starter: measurement model, NCP reformulation (D16, D20)
5. Write `templates/problems_imgrec.jl` — image restoration starter: blur + noise model (D16, D20)

### Phase 2: Script templates
6. Write `templates/script_smoke_test.jl` — main()-wrapped, TeeIO, multi-solver, config hash checks (D5, D6, D15)
7. Write `templates/script_oat.jl` — OAT sensitivity, DB-backed, --quick (D1, D21)
8. Write `templates/script_parameter_search.jl` — LHS search, DB-backed, --quick (D1, D21)
9. Rewrite `templates/script_benchmark.jl` — SQLite, config hash, WorkItem, skip-by-default, --quick (D1, D5, D21)
10. Rewrite `templates/script_figure.jl` → `templates/script_figures_tables.jl` — DB reads, profiles, convergence plots, LaTeX tables (D7)

### Phase 3: Patterns and guides
11. Update `guides/script-patterns.md`:
    - New blocks: config hash, KV CLI parsing, --export, --quick, DB resume, CSV resume+backup, main() wrapping, starting points
    - Update existing: resume (skip-by-default), summary (DB variant), ARGS (key-value)
    - All blocks use main() wrapping and JCODE_ROOT
12. Update `guides/coding-style.md` — add solver interface contract section (D11, D18)
13. Update `guides/experiment-workflow.md` — reference DB-backed pipeline, domain-specific problem files

### Phase 4: Skills
14. Update `/jcode-script` SKILL.md + reference files (D8)
    - Revised Phase 2 questions (type, storage, scope, dependencies)
    - Updated feature blocks referencing new patterns
    - Custom/other option for user-defined scripts
15. Update `/init-project`:
    - Storage backend choice: SQLite (default) or CSV (D4)
    - Problem domain checklist: NLE, CS, image restoration, other (D16)
    - Scaffold: types.jl, benchmark_db.jl (or csv_utils.jl), domain problem files, smoke test (D4, D12, D15)
    - JCODE_ROOT in includes.jl (D17)
16. Update `/optimization-research-workflow` references

### Phase 5: Top-level docs
17. Update toolkit `CLAUDE.md` — template/guide tables (new templates, updated counts)
18. Update `templates/CLAUDE.md.template` — reference DB infrastructure, solver contract
19. Update `templates/jcode-CLAUDE.md.template` — reference solver contract, DB layer, domain files

---

## 5. Additional Decisions (Confirmed 2026-04-02, round 2)

### D9: Minimal common DB schema + extension guidance
- Common columns: `config_hash, problem, dimension, init_point, run_id, converged, iterations, f_evals, cpu_time, flag`.
- The user adds domain-specific columns (e.g., `residual` for nonlinear equations, `psnr`/`ssim` for image reconstruction).
- The template includes comments marking where to add project-specific columns.
- History table follows the same principle: common columns (`k`, `f_evals`, `elapsed`) + project-specific tracking columns.

### D10: `types.jl` template
- Template provides `SolverResult` and `make_result` constructor.
- Common fields: `converged, iterations, f_evals, cpu_time, x, flag, history`.
- User adds domain-specific fields (e.g., `residual`, `Fx`).
- `IterRecord` type for history tracking (common: `k, f_evals, elapsed`; user extends).
- This defines what the DB layer reads/writes — the two templates must stay in sync.

### D11: Solver interface contract
- Every solver must return a `SolverResult` (or equivalent with the same field names).
- Every solver must accept `track::Bool=false` and `callback=nothing` keyword arguments.
- Callback signature: `callback(k::Int, metric::Float64, maxiter::Int) -> nothing`.
- This contract is documented in `guides/coding-style.md` (solver interface section).
- `/jcode-script` and `/init-project` reference this contract when generating solver stubs.

### D12: Problem/projection templates for nonlinear systems
- When scaffolding a new project, `/init-project` asks the problem domain.
- If nonlinear systems: offer to copy starter `problems.jl` and `projections.jl` with the standard interface (`get_problem(id)`, `get_initial_points(dim, prob_id)`, problem struct with `.Q`, `.proj`, `.name`).
- User modifies/extends these with their own problems later.
- For other domains (e.g., image reconstruction): provide stub `problems.jl` with the interface contract but no specific problems.
- Initial points: include the stratified initial point generator as a reusable pattern.

### D13: `--export` pattern as a standard block
- Added to `script-patterns.md` as a composable block.
- Pattern: `if do_export; export_results_csv(db, path); exit(0); end` placed after summary mode.
- `export_results_csv` lives in `benchmark.jl` template.

### D14: Two resume patterns (DB and CSV)
- DB resume: `is_done(db, hash, prob, dim, init)` — skip-by-default, `--force` overrides.
- CSV resume: read existing rows into a `completed::Set`, skip matching keys, `--force` overrides.
- Both patterns documented as blocks in `script-patterns.md`.
- `/jcode-script` selects the right one based on the project's storage backend choice.
- Both use the same CLI interface: skip-by-default + `--force`.

### D15: Smoke test scaffolded by default
- `/init-project` creates a starter `s01_smoke_test.jl` when setting up a new project.
- Minimal: runs solver(s) on one simple problem, prints pass/fail table.
- User extends with config hash checks, more problems, etc.

### D16: Problem domain is a checklist, not single-select
- `/init-project` asks: "What problem domains will this project cover?" with checkboxes:
  - Nonlinear systems (copies `problems.jl` + `projections.jl` starters)
  - Image reconstruction (copies image problem starters)
  - Other / custom (empty `problems.jl` with interface contract only)
- A project can have BOTH nonlinear systems AND image reconstruction (e.g., PHD_FTDFfNoSE has equations benchmark + application experiments).
- Each selected domain adds its starter files. Multiple domains coexist in `src/`.
- The DB schema accommodates all domains (problem field is TEXT, not INT).

### D17: `JCODE_ROOT` constant standardized
- Every project defines `const JCODE_ROOT = @__DIR__` in the include chain (e.g., in `includes.jl` or the module file).
- All scripts use `JCODE_ROOT` instead of `joinpath(@__DIR__, "..")` for paths to `results/`, `src/`, etc.
- Templates and patterns use `JCODE_ROOT` consistently.

### D18: Solver version constants + defaults are required elements
- Every solver file declares: `const {SOLVER}_VERSION = "1.0.0"` and `const {SOLVER}_DEFAULTS = (param1=val1, ...)`.
- These are part of the solver interface contract (D11).
- Style A: declared inside the module, exported.
- Style B: declared at top of solver file, available globally via includes.
- Used by: config hashing (benchmark.jl), smoke test (hash uniqueness checks), parameter search (baseline).

### D19: `make_result` keyword constructor
- `make_result(; converged, iterations, f_evals, cpu_time, x, flag, history=[])` returns a `SolverResult`.
- Used in error/catch paths to create a failed result without running the solver.
- Template in `types.jl`.

### D20: Application domains get separate src/ files
- One `problems.jl` per domain: `problems_nle.jl`, `problems_cs.jl`, `problems_imgrec.jl`, etc.
- A master `problems.jl` (or `includes.jl`) includes the domain-specific files.
- Avoids 2,000+ line mega-files. Each domain file is self-contained.
- `/init-project` creates the appropriate domain files based on the checklist (D16).

### D21: `--quick` mode as standard CLI option
- Benchmark and parameter search scripts support `--quick` for development.
- Reduces dimensions, problem count, and/or starting points for fast iteration.
- Pattern: `if do_quick; sel_dims = dims_small[1:1]; prob_ids = prob_ids[1:3]; end`
- Added to `script-patterns.md` as a composable block.

### D22: CSV backup pattern
- When using CSV storage, back up existing CSV before overwrite:
  `cp raw.csv backup/raw_YYYYMMDD_HHMMSS.csv`
- Added to `script-patterns.md` as a block (CSV path only; SQLite doesn't need it).

### D23: Starting points template with feasibility
- Template includes: labeled starting points generator, feasibility projection, expansion function.
- `starting_points(n; k=10)` returns `Vector{Tuple{String, Vector{Float64}}}`.
- `ensure_feasible(proj, x0)` projects into feasible set if needed.
- Included in `problems.jl` template.

### D24: CLI flags are script-type-driven, refined by user feedback
- Each script type has a **default flag set** based on what makes sense for that use case.
- `/jcode-script` presents the recommended flags and lets the user toggle on/off or add custom flags.
- The flag set is NOT fixed — it's a starting recommendation that adapts to the user's needs.

**Standard flag catalog (available to all scripts):**

| Flag | Type | Purpose |
|------|------|---------|
| `--all` | Boolean | Run all problems/dims/methods (vs. default subset) |
| `--quick` | Boolean | Reduced sweep for development (fewer dims, problems, starts) |
| `--force` | Boolean | Override skip-if-done, re-run everything |
| `--verbose` | Boolean | Progress bar with live iteration info |
| `--summary` | Boolean | Print aggregate stats from DB/CSV, then exit |
| `--export` | Boolean | Dump DB results to CSV, then exit |
| `--problems=` | Key-value | Subset of problems (e.g., `P1,P5,P17`) |
| `--dims=` | Key-value | Subset of dimensions (e.g., `1000,10000`) |
| `--methods=` | Key-value | Subset of methods (e.g., `SFTDFPM,CGPM`) |
| `--tier=` | Key-value | Dimension tier (e.g., `small`, `mid`, `large`) |
| `--profiles` | Boolean | Generate performance profiles only (figures script) |
| `--convergence` | Boolean | Generate convergence plots only (figures script) |
| `--tables` | Boolean | Generate LaTeX tables only (figures script) |

**Default flags per script type:**

| Script type | Default ON | Available (user can add) |
|-------------|-----------|------------------------|
| **Smoke test** | _(none — runs everything)_ | `--verbose` |
| **OAT sensitivity** | `--summary` | `--quick`, `--force`, `--verbose` |
| **Parameter search (LHS)** | `--summary`, `--force` | `--quick`, `--verbose`, `--export` |
| **Benchmark** | `--all`, `--force`, `--verbose`, `--summary`, `--export`, `--quick`, `--problems=`, `--dims=`, `--methods=` | `--tier=` |
| **Figures + tables** | `--all`, `--profiles`, `--convergence`, `--tables`, `--tier=` | `--verbose` |
| **Application** | Same as benchmark | Domain-specific flags (e.g., `--datasets=`, `--noise=`) |
| **Custom** | User decides | Full catalog available |

- `/jcode-script` Phase 2 presents: "Here are the recommended CLI flags for a [type] script. Add/remove?"
- User can also define **custom flags** (e.g., `--datasets=` for logistic regression, `--noise=` for CS).
- The generated script includes the KV CLI parsing block and only the selected flags.

### Dropped: queries.sql
- Not included in templates. Temporary/ad-hoc file, not worth standardizing.

---

## 6. Cross-Project Analysis

Three projects analyzed for pattern extraction:

| Aspect | PHD_FTDFfNoSE | MS_TwoGeneralizedDFM | IRC_MOIN/MISTDFPM |
|--------|--------------|---------------------|-------------------|
| **Style** | B (Flat) | B (Flat) | B (Flat, iterator) |
| **Storage** | SQLite (newer scripts) | CSV only | CSV checkpoints |
| **main() wrap** | Yes | No (older) | No (older) |
| **Solver dispatch** | Separate functions (`solve_sftdfpm`) | `solve(::AbstractMethod)` dispatch | Iterator protocol + `solve(m)` |
| **Problem struct** | `(Q, proj, name)` | `TestProblem(id, name, G, proj, source)` | `Problem(name, F, C, x0, x_star)` |
| **Config hashing** | SHA-based, DB-stored | None | None |
| **App domains** | Nonlinear eqs + image recon | Nonlinear eqs + CS + logistic regression | Nonlinear eqs + traffic + CS + image restoration |
| **Figures/tables** | Combined s70 | Separate s70 (figs) + s75 (tables) | s70 convergence only |
| **Resume** | DB skip-by-default | CSV Set-based, `--resume` | CSV checkpoint merge |
| **Progress** | Callback into solver | ProgressCallback struct | None (log-based) |
| **`--quick` mode** | No | Yes (`--quick` for reduced sweep) | No |

### Key cross-project insights

**6.1 Problem interface varies but has a common core:**
Every project has: a function/operator `F` or `Q`, a constraint/projection `C` or `proj`, an initial point `x0`, and a name. The struct wrapper differs but the contract is the same. Template should define the minimal interface and let users extend.

**6.2 Starting points are universal infrastructure:**
- PHD_FTDFfNoSE: `get_initial_points(dim, prob_id)` — 10 stratified, labeled v1-v10
- MS_TwoGeneralizedDFM: 10 scaled-constant points `(0.4e, 0.5e, ..., 5.0e)` + decaying/ramp
- MISTDFPM: `starting_points(n; k, seed)` + `expand_starting_points` + `ensure_feasible`
- Template should include: labeled starting points, feasibility projection, expansion function.

**6.3 Application domains need separate src/ files, not one mega-problems.jl:**
- MS_TwoGeneralizedDFM: `logreg.jl` as separate module for logistic regression
- MISTDFPM: traffic + CS + image restoration all in one 2,749-line `problems.jl` (unwieldy)
- Better pattern: `problems_nle.jl` (nonlinear equations), `problems_cs.jl` (compressed sensing), `problems_imgrec.jl` (image restoration), etc.

**6.4 `--quick` mode is useful for development:**
- MS_TwoGeneralizedDFM uses `--quick` to reduce dimensions and sweep sizes during development.
- Should be a standard CLI option in benchmark and parameter search scripts.

**6.5 Backup pattern for CSV storage:**
- MS_TwoGeneralizedDFM: copies `raw.csv` → `backup/raw_TIMESTAMP.csv` before overwrite.
- SQLite doesn't need this (atomic writes, old hashes preserved).
- CSV template should include the backup pattern.

**6.6 Figures/tables split is a user choice:**
- Some projects combine (PHD_FTDFfNoSE), some separate (MS_TwoGeneralizedDFM).
- Template should support both. `/jcode-script` asks.

---

## 7. Reference: Real Scripts Analyzed

### Project A: PHD_FTDFfNoSE (SQLite-backed, newest)

| Script | Purpose | Storage | CLI | Key patterns |
|--------|---------|---------|-----|-------------|
| `s01_smoke_test.jl` | Verify all solvers run | None (console) | None | main(), TeeIO, multi-solver loop, config hash checks |
| `s10_sensitivity_oat.jl` | OAT parameter sweeps | CSV+DataFrames | `sweep`, `summary` | main(), TeeIO, NamedTuple rows, shifted geomean |
| `s20_parameter_search.jl` | LHS parameter search | SQLite | `--force`, `--summary` | main(), TeeIO, DB, config hash, LHS sampling |
| `s30_benchmark.jl` | Full benchmark | SQLite | `--all`, `--force`, `--verbose`, `--summary`, `--export`, `--problems=`, `--dims=`, `--methods=` | main(), TeeIO, DB, WorkItem, config hash, callback, selective tracking |
| `s70_figures.jl` | Profiles + plots + tables | SQLite (read) | `--all`, `--profiles`, `--convergence`, `--tables`, `--tier=` | main(), TeeIO, BenchmarkProfiles, LaTeX tables, multi-panel figures |

### Project B: MS_TwoGeneralizedDFM (CSV-based)

| Script | Purpose | Storage | CLI | Key patterns |
|--------|---------|---------|-----|-------------|
| `s10_smoke_test.jl` | Verify setup | Console+log | None | TeeIO, 5-part verification |
| `s45_benchmark.jl` | Full benchmark | CSV | `--all`, `--resume`, `--summary`, `--verbose` | ProgressCallback, backup CSV, Set-based resume |
| `s50_signal_restore.jl` | Compressed sensing | CSV | `--quick`, `--resume`, `--summary` | Problem builder, MSE tracking |
| `s55_logreg.jl` | Logistic regression | CSV | `--quick`, `--resume`, `--summary`, `--datasets=`, `--methods=` | External data loading, accuracy metric |
| `s70_figures.jl` | Figures only | CSV (read) | `--profiles`, `--convergence`, `--scaling`, `--signal` | BenchmarkProfiles, multi-type plots |
| `s75_tables.jl` | Tables only | CSV (read) | None | LaTeX table generators, wins/ties/losses |

### Project C: IRC_MOIN/MISTDFPM (CSV checkpoint, iterator-based)

| Script | Purpose | Storage | CLI | Key patterns |
|--------|---------|---------|-----|-------------|
| `01_smoke_test.jl` | Verify all algorithms | Console+log | None | TeeIO |
| `50_experiment1.jl` | Large-scale comparison | CSV checkpoint | `small`, `mid`, `large`, `benchmark`, `profiles`, `latex`, `summary` | Modular dispatch, tier-based, checkpoint merge |
| `55_experiment2_general.jl` | General constraints | CSV checkpoint | Part-based | Boundary + general constraint problems |
| `60_traffic_application.jl` | Traffic assignment | CSV | Part-based | Domain-specific problem construction |
| `65_compressed_sensing.jl` | CS image recovery | CSV checkpoint | `partA`, `partB`, `fresh` | Image loading, PSNR/SSIM metrics |
| `70_convergence_history.jl` | Convergence plots | CSV (read) | None | In-script solver re-run with tracking |
