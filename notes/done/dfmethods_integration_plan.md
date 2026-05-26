# Task 2 — Research-toolkit + skills integration

> **Status**: Plan complete 2026-05-25. All architectural decisions and
> sub-decisions locked. Ready for implementation review and approval.
> **Toolkit**: `D:\Dropbox\Research\Research-toolkit\` (a Git repo).
> **Library**: `D:\Dropbox\MyJuliaPackages\DF_METHODS\DFMethods.jl\` (v0.3.2 live).
> **Reference**: `D:\Dropbox\MyJuliaPackages\DF_METHODS\DFMethods-starter\` — canonical "what good looks like" for DFMethods integration into a jcode/ tree.

## Context

`DFMethods.jl` v0.3.2 shipped to the Julia General registry as a
configurable derivative-free projection framework. Mohammed's
`/research-toolkit` (Claude Code skill collection) is currently
solver-agnostic; this cycle adds **adaptive pathways** so that
projects targeting the Nonlinear System of Equations (NLE / NLSE)
family get DFMethods.jl-aware scaffolding, while projects in any other
problem class still get the toolkit's full general infrastructure
(SQLite/CSV, script naming, figures, TeeIO, types.jl, Style A/B,
config hashing) without any NLE-specific files.

## Architectural principle — adaptive pathways

The toolkit branches on `/init-project`'s first question:

```
Q1: What's your problem domain?
   ─ (a) Nonlinear System of Equations (NLE / NLSE)
   ─ (b) Something else

If (a) NLE:
   Q2: Solver framework for the F(x)=0 path?
      ─ DFMethods.jl only
      ─ DFMethods.jl + bring-your-own solvers
      ─ No DFMethods (user supplies own solver)
   Q3: Application sub-flavors? (multi-select; optional)
      ☐ Compressed sensing
      ☐ Image restoration
      ☐ Logistic regression
   Q4: Include the 28-problem canonical benchmark library? (default yes)

If (b) Something else:
   (no further problem-domain questions — generic scaffold)
```

Each project is firmly in **one bucket** at the project level
(multi-domain projects → multiple `/init-project` runs).

## Locked decisions

1. **Binary first question**: NLE/NLSE vs Something-else. Restructures the existing Group 3 problem-domain checklist.
2. **NLE sub-flavors**: CS, ImgRec, LogReg live *inside* the NLE path as multi-select sub-flavors (because they reformulate as F(x)=0).
3. **Single-bucket projects**: each `/init-project` run scaffolds one primary domain. If a researcher needs both NLE and something else, they create two projects.
4. **DFMethods opt-in is gated on NLE** (no standalone Group 3b).
5. **Coexistence (DFMethods + BYO)**: ask as the third option of Q2; sub-decision on exact benchmark-script structure still pending.
6. **Canonical 28-problem library**: separate opt-in checkbox in NLE path; default yes.
7. **One file for the 28 problems**: `problems_nle.jl` holds the `TestProblem` struct, 28 problem functions, `PROBLEM_REGISTRY`, `INITIAL_POINTS`, helpers. No split into a `_canonical` suffix file (no good reason; over-engineering).
8. **Constraints in their own file**: `constraints_nle.jl` holds the constraint constructors (`C_nonneg_orthant`, `C_capped_box`, etc.); `problems_nle.jl` cross-references by Julia symbol name. Navigation table at the top of `problems_nle.jl` for easy scanning.
9. **Style-agnostic source**: the 28 problems + constraints are shipped *once* in the toolkit; `/init-project` renders them in the project's chosen style (DFMethods AbstractConstraintSet vs generic `proj::Function`).
10. **Asymmetric script scaffolding by path**: NLE path scaffolds the full s01–s70 set at init time (since the workflow shape is well-known); Something-else path scaffolds only `s01_smoke_test.jl` and users invoke `/jcode-script` to add more as needed.
11. **Style A vs Style B and SQLite vs CSV remain orthogonal**: apply in both paths regardless of NLE choice.
12. **Workflow skill (`optimization-research-workflow`)**: DFMethods touchpoints in all 12 phases.
13. **Doc footprint**: new dedicated `guides/dfmethods-integration.md`; existing guides get short pointers.
14. **Conditional templating**: additive-file pattern; separate `templates/dfmethods/` directory + commented-out blocks in shared templates that the skill uncomments on opt-in. No new templating engine.
15. **Version pin**: `[compat] DFMethods = "0.3.2"` (caret-style).
16. **Threaded default**: serial (`--threads=1`); users opt into threading via CLI flag.

## Sub-decisions resolved

**S1. `extras.jl` — always scaffolded as empty skeleton** when DFMethods is opted in. Comment block at the top lists the 4 extension contracts (`AbstractSearchDirection`, `LineSearch.AbstractLineSearchAlgorithm`, `AbstractInertialRule`, `AbstractIterateUpdate`) with pointers to `DFMethods.jl/examples/*.jl` as canonical templates. No extra Q5; the file appears whenever DFMethods is opted in.

**S2. Constraints file naming — single `constraints_nle.jl`** holds all constraint factories used by the project (canonical 28-problem constraints when Q4=yes, plus any user-added constraints for project-specific problems). The guide will describe the convention. No separate `_extra` file.

**S3. Coexistence benchmark structure — single `s30_benchmark.jl` with mixed palette**. Each palette entry carries a `solver_kind::Symbol` (`:dfmethods` vs `:custom`); the resolver dispatches to `solve_with_alg` (DFMethods) vs `solve_with_custom` (BYO) per entry. One config-hash space, one DB schema, simpler `s70_figures.jl` profiles. The same single-file convention applies to `s40_recovery.jl` and `s70_figures.jl` for coexistence mode.

## Scaffolded files per branch

### Path A (NLE) — files vary with Q2/Q3/Q4 answers

**Always present in Path A:**

```
jcode/
├── Project.toml                # has standard deps; +DFMethods if Q2 = DFMethods opt-in
├── Manifest.toml               # committed for reproducibility
├── CLAUDE.md                   # impl-level instructions; DFMethods section uncommented if Q2 yes
├── src/
│   ├── includes.jl             # Style B
│   ├── deps.jl                 # Style B
│   ├── {ModuleName}.jl         # Style A
│   ├── types.jl                # SolverResult, IterRecord
│   ├── io_utils.jl             # TeeIO
│   ├── benchmark.jl            # SQLite CRUD (if SQLite backend)
│   ├── constraints_nle.jl      # constraint constructors
│   └── problems_nle.jl         # TestProblem registry; either 28-problem-populated (Q4 yes) or empty skeleton (Q4 no)
├── scripts/                    # FULL s01–s70 set always scaffolded in NLE path
│   ├── s01_smoke_test.jl
│   ├── s10_oat_sensitivity.jl
│   ├── s20_parameter_search.jl
│   ├── s30_benchmark.jl        # DFMethods-aware if Q2 = DFMethods; generic if Q2 = no DFMethods
│   ├── s40_recovery.jl
│   └── s70_figures_tables.jl
├── test/                       # Style A only
└── results/logs/
```

**Added if Q3 sub-flavors checked:**

```
src/
├── problems_cs.jl              # if "Compressed sensing" checked
├── problems_imgrec.jl          # if "Image restoration" checked
└── problems_logreg.jl          # if "Logistic regression" checked

scripts/
├── s50_compressed_sensing.jl   # if CS checked
├── s55_image_restoration.jl    # if ImgRec checked
└── s60_logistic_regression.jl  # if LogReg checked
```

**Added if Q2 = DFMethods opt-in (any variant):**

```
src/
├── adapter.jl                  # solve_with_alg + retcode mapping
├── callbacks.jl                # ProgressUpdateCallback
├── sweep_helpers.jl            # WorkItem, register_palette, run_sweep
└── extras.jl                   # (placement pending S1)
```

### Path B (Something else) — toolkit's generic scaffold

```
jcode/
├── Project.toml                # standard deps; no DFMethods
├── Manifest.toml
├── CLAUDE.md
├── src/
│   ├── includes.jl / deps.jl (Style B) OR {ModuleName}.jl (Style A)
│   ├── types.jl
│   ├── io_utils.jl
│   └── benchmark.jl            # if SQLite backend
├── scripts/
│   └── s01_smoke_test.jl       # generic; user invokes /jcode-script for more
├── test/                       # Style A only
└── results/logs/
```

User writes their own problem definitions and solver invocations in
whatever shape their domain calls for.

## `/jcode-script` — adaptive on detection

When invoked in an existing project:

- If `jcode/src/adapter.jl` is present (NLE path + DFMethods opt-in) → offer DFMethods-aware s30/s40/s70 variants by default.
- Otherwise (NLE without DFMethods, or Something-else path) → offer the toolkit's existing generic templates.

The script-naming convention (`s{NN}_{name}` with 10-step increments) and CLI-flag catalog (`--all`, `--quick`, `--force`, `--verbose`, `--summary`, `--export`, `--problems=`, `--dims=`, `--methods=`, etc.) is shared infrastructure that applies to both paths.

## New files (under `templates/dfmethods/`)

```
templates/dfmethods/
├── adapter_template.jl                # port of DFMethods-starter/jcode/src/adapter.jl
├── callbacks_template.jl              # port of DFMethods-starter/jcode/src/callbacks.jl
├── sweep_helpers_template.jl          # port of DFMethods-starter/jcode/src/sweep_helpers.jl
├── problems_nle_template.jl           # one unified file: TestProblem schema + 28 problems + registry + initial points
├── constraints_nle_template.jl        # constraint constructors (C_nonneg_orthant, etc.)
├── problems_cs_template.jl            # sub-flavor template for CS
├── problems_imgrec_template.jl        # sub-flavor template for ImgRec
├── problems_logreg_template.jl        # sub-flavor template for LogReg
├── script_smoke_test_dfmethods.jl
├── script_oat_dfmethods.jl
├── script_parameter_search_dfmethods.jl
├── script_benchmark_dfmethods.jl      # port of s30_benchmark.jl (palette genericized)
├── script_recovery_dfmethods.jl       # port of s40_recovery.jl
├── script_figures_dfmethods.jl        # port of s70_figures.jl
├── script_compressed_sensing.jl       # s50
├── script_image_restoration.jl        # s55
├── script_logistic_regression.jl      # s60
└── dfmethods_extras_template.jl       # (if S1 = always-scaffold)
```

## New guide

`guides/dfmethods-integration.md` — 13-section single source of truth:

1. Purpose & scope (when this guide applies: NLE path + DFMethods opted in)
2. Library overview (v0.3.2 capability surface)
3. Adapter boundary: `NonlinearSolution → SolverResult`
4. Constraint-set selection table
5. TestProblem registry pattern (single-file design)
6. Coexistence: DFMethods + BYO solvers
7. Palette construction & config hashing
8. Live progress: `ProgressUpdateCallback`
9. Threaded sweeps
10. Recovery sweeps (s40)
11. Figures (s70)
12. Don't edit `DFMethods.jl` itself (custom extensions go in `extras.jl`)
13. Reference links (tutorial, starter, DOIs)

## Skill edits summary

### `skills/init-project/SKILL.md`

- Restructure Group 3 around the binary first question.
- Conditional reads + conditional population gated on the four NLE-path questions.
- Add `references/dfmethods-quickref.md` (cheat sheet of `DFProjection` kwargs + 6 built-in constraint sets).

### `skills/jcode-script/SKILL.md`

- Phase 1 detection: check for `jcode/src/adapter.jl`.
- Phase 2 Q1: new rows in script-type table for DFMethods-aware variants.
- Phase 3 Steps 1–2: dispatch to DFMethods-variant templates when adapter.jl is present.

### `skills/optimization-research-workflow/SKILL.md`

- Top callout under Quick Start.
- 12 phase-by-phase DFMethods footnotes (one per phase).
- Structure diagram gains optional `adapter.jl`, `callbacks.jl`, `sweep_helpers.jl` (marked optional).
- `references/benchmark-patterns.md` gains a short DFMethods subsection.

## Shared templates (append commented-out conditional blocks)

- `templates/Project.toml.template`
- `templates/includes_template.jl`
- `templates/deps_template.jl`
- `templates/types_template.jl`
- `templates/CLAUDE.md.template`
- `templates/jcode-CLAUDE.md.template`

Each gets a `# If using DFMethods.jl, uncomment:` block at the end. `/init-project` uncomments these blocks at scaffold time when Q2 ≠ "no DFMethods".

## Conservation guarantees

- **Path B (Something else)** scaffolds are byte-identical to the toolkit's pre-integration baseline.
- **Path A (NLE) without DFMethods opt-in** uses the standard `proj::Function`-based problem schema; no DFMethods deps in Project.toml.
- Style A vs Style B branching untouched.
- SQLite vs CSV branching untouched.
- All non-init/non-script skills (math-research-writer, review-paper, suggest-journals, etc.) untouched.

## Sequencing (commit order on the toolkit repo)

1. **Commit 1 — Guide.** `guides/dfmethods-integration.md` + short pointers in `coding-style.md`, `script-patterns.md` (new Blocks 29–30), `experiment-workflow.md`. Safe to land first; no behavior change.
2. **Commit 2 — Templates.** `templates/dfmethods/` directory with the new files; commented-out blocks appended to the 6 shared templates.
3. **Commit 3 — `/init-project` edits.** Restructured Group 3 binary question + NLE-path follow-ups + conditional reads/population.
4. **Commit 4 — `/jcode-script` edits.** Detection + DFMethods-aware script-type rows + infrastructure check.
5. **Commit 5 — `/optimization-research-workflow` edits.** Callout, footnotes, structure-diagram annotations.
6. **Commit 6 — Toolkit-root docs.** `CLAUDE.md` + `README.md` mention DFMethods integration.
7. **Commit 7 — End-to-end smoke test.** Validation steps below in scratch directories.
8. **Push + redeploy.** `git push origin main`; `git pull` at `~/.claude/skills/research-toolkit/`.

## Verification

End-to-end test, executed in scratch directories under `D:\Dropbox\Research\_scratch\`:

### Test 1 — NLE / DFMethods only / canonical library yes / no sub-flavors

1. Run `/init-project`. Answers: Style B, SQLite, Q1=NLE, Q2=DFMethods only, Q3=(none), Q4=yes.
2. Verify the full file tree per "Path A" above is generated.
3. Mohammed runs: `julia --project=jcode/ -e 'using Pkg; Pkg.instantiate()'` then `julia --project=jcode/ jcode/scripts/s01_smoke_test.jl`. Should resolve DFMethods 0.3.2 from registry and exit cleanly.
4. Mohammed runs: `julia --project=jcode/ jcode/scripts/s30_benchmark.jl --ls=LSI --dims=1000 --problems=1 --maxiter=200`. Should complete one solve, insert one row.

### Test 2 — NLE / DFMethods + BYO / sub-flavors checked / canonical library yes

Same as Test 1 but with Q2=coexistence, Q3=CS+ImgRec checked. Verify additional problems_cs.jl, problems_imgrec.jl, s50_compressed_sensing.jl, s55_image_restoration.jl land. Coexistence-specific `problems_nle.jl` shape (depends on S3 outcome).

### Test 3 — NLE / no DFMethods / canonical library yes

Q2=no DFMethods. Verify `problems_nle.jl` uses generic `proj::Function`-based schema; no adapter/callbacks/sweep_helpers files; Project.toml has no DFMethods deps. Script set still scaffolds full s01–s70 but in generic form.

### Test 4 — Something else

Q1=Something else. Verify only the generic Path B files appear; no adapter/callbacks/sweep_helpers, no problems_nle.jl, no DFMethods deps, only `s01_smoke_test.jl` in scripts/.

### Test 5 — Conservation check

Repeat Test 4 and diff against a saved pre-integration baseline snapshot. Must be byte-identical.

## Out of scope

- Editing `DFMethods.jl` itself.
- Writing paper-side content.
- Locking the toolkit to DFMethods (every change is opt-in; default Path B stays solver-agnostic; non-NLE projects are byte-identical to pre-integration).
- Application-domain support beyond NLE (approximation, vector optimization, eigenvalue, etc.) — research-specific; users carry these in their own projects.
- Modifying `DFMethods-starter`.

## Critical files for implementation

Skills (3):

- `D:\Dropbox\Research\Research-toolkit\skills\init-project\SKILL.md`
- `D:\Dropbox\Research\Research-toolkit\skills\jcode-script\SKILL.md`
- `D:\Dropbox\Research\Research-toolkit\skills\optimization-research-workflow\SKILL.md`

New guide:

- `D:\Dropbox\Research\Research-toolkit\guides\dfmethods-integration.md`

New templates (under `D:\Dropbox\Research\Research-toolkit\templates\dfmethods\`):

- `problems_nle_template.jl` (single-file 28 problems + registry)
- `constraints_nle_template.jl`
- `adapter_template.jl`, `callbacks_template.jl`, `sweep_helpers_template.jl`
- 9 script templates (s01/s10/s20/s30/s40/s50/s55/s60/s70 DFMethods-aware variants)
- `problems_cs_template.jl`, `problems_imgrec_template.jl`, `problems_logreg_template.jl`

Source references (read-only):

- `D:\Dropbox\MyJuliaPackages\DF_METHODS\DFMethods-starter\jcode\src\{adapter,callbacks,sweep_helpers,problems_nle,problems_cs,problems_imgrec,problems_logreg}.jl`
- `D:\Dropbox\MyJuliaPackages\DF_METHODS\DFMethods-starter\jcode\scripts\{s30_benchmark,s40_recovery,s70_figures}.jl`

## Plan provenance

Authored 2026-05-25 in plan mode:

- **Phase 1 (Explore)** — one Explore agent mapped `D:\Dropbox\Research\Research-toolkit\` (skills, templates, conventions).
- **Phase 2 (Plan)** — one Plan agent designed the implementation; surfaced 6 open questions (4 answered via AskUserQuestion in Phase 3, 2 deferred).
- **Phase 3 (Review)** — iterative AskUserQuestion rounds + design discussion:
  - Locked: discovery placement, coexistence shape, workflow-skill depth, doc footprint.
  - Locked: TestProblem unified-struct design, canonical 28-problem library opt-in (default yes).
  - **Architectural reframe**: toolkit branches on Q1 (NLE vs Something-else); DFMethods opt-in is gated on NLE; CS/ImgRec/LogReg become NLE sub-flavors not separate domains; projects are single-bucket.
  - Locked: single-file problems_nle.jl (no canonical-suffix split); asymmetric script scaffolding (NLE = full s01–s70; Something-else = s01 only).
- **Phase 4 (Final plan)** — this note. All three sub-decisions resolved (S1: always-scaffold extras.jl; S2: single constraints_nle.jl; S3: single s30 with mixed palette).
- **Phase 5 (ExitPlanMode)** — called 2026-05-25.
