---
name: jcode-script
description: Create experiment scripts with consistent structure and patterns.
  Guides through script type selection, storage backend, CLI flags, feature
  composition, dependency management, and infrastructure setup. Ensures scripts
  follow established conventions for DB/CSV I/O, skip-by-default resume,
  config hashing, logging, and main() wrapping.
invocation: user
---

# /jcode-script — Experiment Script Generator

Create experiment scripts with consistent structure and patterns. Works with both Style A (Module Package) and Style B (Flat Include) Julia projects.

## Workflow

### Phase 1: Context Discovery

Before asking any questions, gather project context:

1. **Read the project's `CLAUDE.md`** (or `jcode/CLAUDE.md`) to determine:
   - Coding architecture: Style A (module) or Style B (flat include)
   - Algorithm name, problem domain, key types
   - Existing dependencies
   - Module name (Style A) or entry point path (Style B)
   - Storage backend already in use (SQLite or CSV)

2. **Scan existing scripts** in `scripts/` (or ask user for location if no standard structure):
   - List existing `s{NN}_*.jl` files to determine next available number
   - Note which features are already in use (DB, resume, summary, etc.)

3. **Check existing infrastructure**:
   - Does `io_utils.jl` exist? Does it have TeeIO, setup_logging, teardown_logging?
   - Does `benchmark.jl` exist? Does it have open_db, make_config_hash, etc.?
   - Does `types.jl` exist? Does it have SolverResult, make_result?
   - Does `results/` directory exist? What subdirectories?

If the project directory structure is not standard, ask where to save the script and where the source code lives.

### Phase 2: User Questions

Ask the user interactively:

#### Question 1: Script Type

Present script types with suggested `s{NN}_` numbers based on **logical order** in the experiment pipeline. If an existing script already occupies a number, suggest the next available gap.

| Logical Order | Type | Suggested Prefix | Purpose |
|---|---|---|---|
| 1 | Smoke test | `s01_` | Verify all solvers run, config hash uniqueness |
| 2 | OAT sensitivity | `s10_` | One-at-a-time parameter sweeps |
| 3 | Parameter search (LHS) | `s20_` | Latin Hypercube sampling for best params |
| 4 | Benchmark | `s30_` | Full benchmark: methods × problems × dims × inits |
| 5 | Application | `s50_`–`s65_` | Domain-specific experiments (CS, image, traffic, etc.) |
| 6 | Figures + tables | `s70_` | Performance profiles, convergence plots, LaTeX tables |
| 7 | Custom | User specifies | Any other script type |

**Numbering rules:**
- Scripts are numbered in increments of 10 (with 5-gaps for insertion)
- If `s10_` exists and user wants another sensitivity script, suggest `s11_` or `s12_`
- Always confirm the final name with the user

#### Question 2: Storage Backend

Only ask on the **first script creation** per project. Subsequent scripts inherit the project's choice.

> "This project uses [SQLite / CSV / not yet decided]. SQLite is recommended (single DB file, atomic writes, queryable, content-addressable config hashing). Do you want SQLite (default) or CSV?"

- **SQLite** (default): Uses `benchmark.jl` with `open_db`, `make_config_hash`, `ensure_config!`, `is_done`, `insert_result!`, `insert_history!`. Includes `--export` flag for CSV output.
- **CSV**: Uses manual CSV I/O with `flush()` per row, Set-based skip logic, and backup before overwrite.

If SQLite is chosen and `benchmark.jl` doesn't exist, create it from `templates/benchmark_db_template.jl`.

#### Question 3: CLI Flags

Present the **recommended flag set** for the chosen script type. Let the user toggle on/off or add custom flags.

**Standard flag catalog:**

| Flag | Type | Purpose |
|------|------|---------|
| `--all` | Boolean | Run all problems/dims/methods (vs. default subset) |
| `--quick` | Boolean | Reduced sweep for development |
| `--force` | Boolean | Override skip-if-done, re-run everything |
| `--verbose` | Boolean | Progress bar with live iteration info |
| `--summary` | Boolean | Print aggregate stats, then exit |
| `--export` | Boolean | Dump DB results to CSV, then exit |
| `--problems=` | Key-value | Subset of problems |
| `--dims=` | Key-value | Subset of dimensions |
| `--methods=` | Key-value | Subset of methods |
| `--tier=` | Key-value | Dimension tier (small, mid, large) |
| `--profiles` | Boolean | Profiles only (figures script) |
| `--convergence` | Boolean | Convergence plots only (figures script) |
| `--tables` | Boolean | LaTeX tables only (figures script) |

**Default flags per script type:**

| Script type | Default ON | Available (user can add) |
|-------------|-----------|------------------------|
| **Smoke test** | _(none)_ | `--verbose` |
| **OAT sensitivity** | `--summary`, `--force` | `--quick`, `--verbose`, `--export` |
| **Parameter search** | `--summary`, `--force`, `--quick` | `--verbose`, `--export` |
| **Benchmark** | `--all`, `--force`, `--verbose`, `--summary`, `--export`, `--quick`, `--problems=`, `--dims=`, `--methods=` | `--tier=` |
| **Figures + tables** | `--all`, `--profiles`, `--convergence`, `--tables`, `--tier=` | `--verbose` |
| **Application** | Same as benchmark | Domain-specific (e.g., `--datasets=`, `--noise=`) |
| **Custom** | User decides | Full catalog available |

Present: "Here are the recommended CLI flags for a [type] script: [list]. Add/remove/customize?"

#### Question 4: Scope / Features

Context-dependent based on script type:

- **Smoke test**: Which solvers to test? Config hash checks?
- **OAT/LHS**: Which parameters to sweep? What dimensions? How many samples?
- **Benchmark**: Which methods? Dimension tiers? History tracking subset?
- **Figures + tables**: Which outputs? (profiles, convergence, tables) Which tiers?
- **Application**: What domain? What metrics (MSE, PSNR, accuracy)?
- **Custom**: What does this script do? What data does it read/write?

#### Question 5: Dependencies

After determining features, check which packages are needed and not yet available.

> "This script needs [package list]. Should I add them to [Project.toml / deps.jl], or will you?"

See `references/dependency-guide.md` for the feature → package mapping.

### Phase 3: Generate

#### Step 1: Infrastructure Check

Before generating the script, ensure supporting files exist.

**`io_utils.jl`** — Required for all scripts (TeeIO logging is default):
- Check if `io_utils.jl` exists in `src/`
- If missing: create from toolkit's `io_utils.jl` pattern (see `references/infrastructure-patterns.md`)
- If exists: verify it has `setup_logging`, `teardown_logging`

**`types.jl`** — Required for scripts that run solvers:
- Check if `types.jl` exists in `src/`
- If missing: create from `templates/types_template.jl`
- Must have: `SolverResult`, `IterRecord`, `make_result`

**`benchmark.jl`** — Required if SQLite backend is selected:
- Check if `benchmark.jl` exists in `src/`
- If missing: create from `templates/benchmark_db_template.jl`
- Must have: `open_db`, `make_config_hash`, `ensure_config!`, `is_done`, `insert_result!`, `insert_history!`

**Integration after creating infrastructure files:**
- **Style A**: Add `include(...)` to module file, add exports
- **Style B**: Add `include(...)` to `includes.jl` in correct dependency order

**`results/` directories:**
- Ensure `results/logs/` exists (for TeeIO)
- Ensure `results/figures/` exists (for figure scripts)

#### Step 2: Compose the Script

Assemble the script from the selected feature blocks. The script follows this structure:

```
1. Header comment block (goal, output, usage with selected flags)
2. Load path / imports
3. WorkItem struct (if benchmark — must be outside main())
4. function main()
5.   CLI flag parsing (only selected flags)
6.   Setup logging (TeeIO)
7.   Open DB (if SQLite) or setup CSV paths
8.   Configuration constants
9.   Summary/export early exit (if selected)
10.  Helper functions (if needed)
11.  Main loop / work list construction
12.  Main loop body (with try-catch, progress, DB/CSV writes)
13.  Final summary
14.  Cleanup (teardown logging)
15. end
16. main()
```

See `../../guides/script-patterns.md` for the code block for each feature.

#### Step 3: Adapt to Project

Replace all placeholder names with project-specific values:
- Module name / include path
- Algorithm function name and solver params
- Problem getter function (`get_problem`)
- Result field names
- DB/CSV column names matching the project's data model
- Results directory names

#### Step 4: Verify

After generating, verify:
- [ ] All imports are available (either in module or deps.jl)
- [ ] Infrastructure files (io_utils.jl, types.jl, benchmark.jl) are included
- [ ] Results directory will be created by the script (mkpath)
- [ ] Script header comment has correct usage examples with selected flags
- [ ] DB columns / CSV headers match the @printf format strings
- [ ] Script is wrapped in `function main() ... end` + `main()` at bottom
- [ ] JCODE_ROOT is used for paths (not `joinpath(@__DIR__, "..")`)

## Reference Files

- `../../guides/script-patterns.md` — 28 composable code blocks for each feature
- `references/infrastructure-patterns.md` — Canonical io_utils.jl code
- `references/dependency-guide.md` — Feature → package mapping, installation instructions
