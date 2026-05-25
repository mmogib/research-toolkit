---
name: optimization-research-workflow
description: End-to-end workflow for optimization algorithm research projects.
  Guides through theory, Julia implementation, parameter tuning, benchmarking,
  and paper writing. Use when starting a new optimization research project or
  when needing guidance on the next phase.
invocation: user
---

# Optimization Research Workflow

End-to-end workflow for developing, benchmarking, and publishing optimization algorithms in Julia. Extracted from the MISTDFPM project's battle-tested process.

## Quick Start

1. **Scaffold a new project** using one of:
   - **Full project**: Run `/init-project` — interactive scaffolding with all templates.
   - **Single template**: Copy from `../../templates/` (e.g., `../../templates/main.tex.template`).

2. **Customize `CLAUDE.md`** — fill in algorithm name, problem class, constraint types.

3. **Customize `jcode/CLAUDE.md`** — fill in algorithm parameters, presets, step descriptions.

4. **Follow the phases below** in order. Each phase has clear decision rules for when to proceed.

### DFMethods.jl projects

If your algorithm sits in the **DFMethods.jl** framework (built-in
direction / line-search / inertial / iterate-update palette, custom
callbacks, `solve(prob, alg)` API), opt into the integration at
`/init-project`'s NLE-path solver-framework question. The 12 phases
below are unchanged in shape, but each gains a DFMethods touchpoint
(see "DFMethods Touchpoints" below the table). Single source of truth
for the integration patterns: `../../guides/dfmethods-integration.md`.

## Project Structure

```
your-project/
├── CLAUDE.md              # Project-level context (algorithm, status, rules)
├── jcode/
│   ├── CLAUDE.md          # Implementation-level context (params, scripts, usage)
│   ├── Project.toml       # Julia project dependencies
│   ├── src/               # Source code
│   │   ├── includes.jl    # Entry point (defines JCODE_ROOT)
│   │   ├── deps.jl        # Package imports (ALL shared deps here)
│   │   ├── types.jl       # SolverResult, IterRecord, make_result
│   │   ├── io_utils.jl    # TeeIO, setup_logging, teardown_logging
│   │   ├── algorithm.jl   # Main algorithm (struct + iterator + solve)
│   │   ├── problems_nle.jl  # Nonlinear equations test problems
│   │   ├── problems_cs.jl   # (optional) Compressed sensing
│   │   ├── benchmark.jl   # DB infrastructure (config hash, CRUD)
│   │   ├── adapter.jl     # (DFMethods projects) NonlinearSolution → SolverResult
│   │   ├── callbacks.jl   # (DFMethods projects) ProgressUpdateCallback
│   │   ├── sweep_helpers.jl  # (DFMethods projects) WorkItem, register_palette, run_sweep
│   │   ├── extras.jl      # (DFMethods projects) custom directions / line searches / …
│   │   └── constraints_nle.jl  # (DFMethods projects) constraint set constructors
│   ├── scripts/           # Experiment scripts (skip-by-default, --force)
│   │   ├── s01_smoke_test.jl
│   │   ├── s30_benchmark.jl
│   │   └── s70_figures_tables.jl
│   └── results/
│       ├── experiments.db  # SQLite: all experiment data
│       ├── logs/           # TeeIO log files
│       └── figures/        # Generated plots and tables
├── paper/                 # LaTeX manuscript
├── refs/                  # Reference papers (PDFs)
└── notes/                 # Plans, session findings, working documents
```

## Workflow Phases

| # | Phase | Gate to proceed | Typical duration |
|---|-------|----------------|-----------------|
| 0 | Project Setup | Template instantiated, CLAUDE.md customized | 1 session |
| 1 | Theory Review | Algorithm understood, proofs checked | 1-2 sessions |
| 2 | Core Implementation | Algorithm struct + iterator + solve working | 2-3 sessions |
| 3 | Reference Algorithms | Comparison methods implemented | 1-2 sessions |
| 4 | Smoke Tests | All algorithms pass on small problems | 1 session |
| 5 | Sensitivity Analysis | Critical parameters identified | 1-2 sessions |
| 6 | Parameter Search | Tuned defaults found via LHS | 1-2 sessions |
| 7 | Large-Scale Experiments | Multi-dim x multi-problem x multi-start results | 1-2 sessions |
| 8 | Application Experiments | Domain-specific results (CS, traffic, etc.) | 1-3 sessions |
| 9 | Paper Writing | Results tables, profiles, discussion | 2-3 sessions |
| 10 | Literature Review | Introduction, related work | 1-2 sessions |
| 11 | Polish & Submit | Notation, proofs, abstract, final check | 1-2 sessions |

**See `../../guides/experiment-workflow.md` for detailed phase descriptions, decision rules, and common pitfalls.**

### DFMethods.jl touchpoints (only if the project opted into DFMethods at init time)

| # | Phase | DFMethods touchpoint |
|---|---|---|
| 0 | Project Setup | Confirm `julia --project=jcode/ -e 'using DFMethods; println(pkgversion(DFMethods))'` prints `0.3.2+`. |
| 1 | Theory Review | Library docstrings carry DOI citations for each component (Solodov–Svaiter, La Cruz, Ibrahim 2024 STTDFPM, Halpern, Maingé). Read alongside your reference papers. Extension templates at `DFMethods.jl/examples/`. |
| 2 | Core Implementation | Custom algorithm parts (direction / line-search / inertial / iterate-update) subtype the relevant abstract type and live in `jcode/src/extras.jl`. The library's `step!` framework handles the iteration. See `../../guides/dfmethods-integration.md` § 12. |
| 3 | Reference Algorithms | Comparison methods register in the palette via `sweep_helpers.jl::resolve_method`. Built-in DFMethods options (e.g., `ResidualNormBacktrack`, `AdaptiveClampedBacktrack`) cost zero implementation work — just add a label + a `resolve_method` branch. Non-DFMethods baselines go through their own adapter (e.g., `solve_with_nonlinearsolve` wrapping NonlinearSolve.jl into `SolverResult`). |
| 4 | Smoke Tests | `s01_smoke_test.jl` exercises the adapter + palette + config-hash flow on a small problem; verifies `using DFMethods; using SciMLBase` loads and `solve_with_alg(F, set, x0, DFProjection())` returns a `SolverResult`. |
| 5 | Sensitivity Analysis | `s10_oat_sensitivity.jl` sweeps the algorithm-level params (`r` for `SpectralThreeTerm`, `σ`/`ρ` for line searches, `θ` for `Inertial`, `ζ` for the iterate-update step, `γ` for `SolodovSvaiterProjection` if the relaxation factor is in scope). Use `build_params` for hash canonicalization. |
| 6 | Parameter Search | `s20_parameter_search.jl` (LHS) samples the params NamedTuple and feeds each sample through `register_palette` (one palette entry per sample). Producer/consumer threaded variant of `run_sweep` cuts wall time roughly linearly in `cli[:threads]`. |
| 7 | Large-Scale Experiments | Canonical `s30_benchmark.jl` use case — palette × problems × dims × inits, threaded sweep, skip-by-default resume. Reference: `DFMethods-starter/scripts/s30_benchmark.jl`. |
| 8 | Application Experiments | Domain-specific application problems (CS, ImgRec, LogReg) live in `problems_cs.jl` / `problems_imgrec.jl` / `problems_logreg.jl` with `TestProblem.set_factory` returning the appropriate `AbstractConstraintSet`. `s50_*`–`s65_*` scripts follow the same sweep pattern. |
| 9 | Paper Writing — Results | `s70_figures.jl` produces Dolan–Moré performance profiles. `BenchmarkProfiles.jl` integration uses manual `performance_profile_data` + `plot!` loop (the high-level call collapses per-series kwargs). Log2 x-axis with integer exponent labels. |
| 10 | Literature Review | Library docstring DOI citations form a ready-made bibliography spine. The originator entries (`@Solodov1999`, `@LaCruz2006`, `@Dai2015`, `@Abubakar2022`, `@Ibrahim2023a`, `@Halpern1967`, `@Alvarez2001`, `@Mainge2008`) are the canonical set to cite when referring to DFMethods components. |
| 11 | Polish & Submit | Cite DFMethods.jl in the paper (`CITATION.cff` + Zenodo DOI on the repo's `README.md`; current concept DOI badge tracks latest). Confirm `Project.toml` pins `DFMethods = "0.3.2"` (or whichever version produced the results) and `Manifest.toml` is **committed** in `jcode/` for paper reproducibility. |

## Key Patterns

- **SQLite + config hashing** — All experiment results stored in `experiments.db` with content-addressable config hashes. The SAME NamedTuple is hashed AND splatted to the solver — zero divergence.
- **Skip-by-default + `--force`** — Completed runs are skipped automatically. Use `--force` to re-run. No accidental data loss.
- **CLI flags** — Scripts support `--all`, `--quick`, `--force`, `--verbose`, `--summary`, `--export`, `--problems=`, `--dims=`, `--methods=`. See `../../guides/script-patterns.md`.
- **Solver contract** — Every solver returns `SolverResult`, accepts `track=false` + `callback=nothing`, declares `VERSION` and `DEFAULTS`. See `../../guides/coding-style.md`.
- **`main()` wrapping** — All scripts wrap body in `function main() ... end` for Julia scoping safety.
- **TeeIO logging** — All scripts log to both console and timestamped file via `setup_logging`.
- **DFMethods.jl adapter** (DFMethods projects only) — `solve_with_alg(F, set, x0, alg::DFProjection)` in `src/adapter.jl` bridges `SciMLBase.NonlinearSolution` to `SolverResult` at the script boundary. See `../../guides/dfmethods-integration.md`.

## Rules

1. **DO NOT compile LaTeX.** The user compiles.
2. **DO NOT run scripts automatically.** The user runs scripts unless they explicitly ask.
3. **All shared deps in `deps.jl`.** Never add `using` in other `src/` files.
4. **Notes workflow.** Plans go to `notes/plan_*.md`. Session findings go to `notes/`.
5. **Status tracking.** Keep `CLAUDE.md` current with completed items, findings, next steps.

## Reference Files

- `../../guides/experiment-workflow.md` — Detailed 12-phase guide with decision rules
- `../../guides/script-patterns.md` — Reusable Julia script patterns
- `../../guides/dfmethods-integration.md` — DFMethods.jl integration patterns (only for projects that opted into DFMethods at init time)
- `references/benchmark-patterns.md` — Benchmarking infrastructure patterns
- `references/claude-md-guide.md` — How to write effective CLAUDE.md files
- `references/template-usage.md` — How to instantiate and customize the template
