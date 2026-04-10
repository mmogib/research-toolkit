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
│   │   └── benchmark.jl   # DB infrastructure (config hash, CRUD)
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

## Key Patterns

- **SQLite + config hashing** — All experiment results stored in `experiments.db` with content-addressable config hashes. The SAME NamedTuple is hashed AND splatted to the solver — zero divergence.
- **Skip-by-default + `--force`** — Completed runs are skipped automatically. Use `--force` to re-run. No accidental data loss.
- **CLI flags** — Scripts support `--all`, `--quick`, `--force`, `--verbose`, `--summary`, `--export`, `--problems=`, `--dims=`, `--methods=`. See `../../guides/script-patterns.md`.
- **Solver contract** — Every solver returns `SolverResult`, accepts `track=false` + `callback=nothing`, declares `VERSION` and `DEFAULTS`. See `../../guides/coding-style.md`.
- **`main()` wrapping** — All scripts wrap body in `function main() ... end` for Julia scoping safety.
- **TeeIO logging** — All scripts log to both console and timestamped file via `setup_logging`.

## Rules

1. **DO NOT compile LaTeX.** The user compiles.
2. **DO NOT run scripts automatically.** The user runs scripts unless they explicitly ask.
3. **All shared deps in `deps.jl`.** Never add `using` in other `src/` files.
4. **Notes workflow.** Plans go to `notes/plan_*.md`. Session findings go to `notes/`.
5. **Status tracking.** Keep `CLAUDE.md` current with completed items, findings, next steps.

## Reference Files

- `../../guides/experiment-workflow.md` — Detailed 12-phase guide with decision rules
- `../../guides/script-patterns.md` — Reusable Julia script patterns
- `references/benchmark-patterns.md` — Benchmarking infrastructure patterns
- `references/claude-md-guide.md` — How to write effective CLAUDE.md files
- `references/template-usage.md` — How to instantiate and customize the template
