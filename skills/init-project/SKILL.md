---
name: init-project
description: Interactive scaffolding for research projects, and the sole owner of the root CLAUDE.md
  hub. Default mode creates the full directory structure (paper/, jcode/, notes/, refs/), populates
  CLAUDE.md files, sets up Julia with a chosen architecture (Style A Module or Style B Flat Include),
  and copies templates. Adopt mode brings an existing or legacy project onto the hub — migrating an
  old CLAUDE.md, scaffolding only what is missing, and never touching existing code. Use for a new
  project, for joining an existing one, or when a project's CLAUDE.md predates the hub shape.
invocation: user
---

# /init-project — Research Project Scaffolding and Adoption

This skill owns "make this directory conform to the toolkit." Every other skill that can be the first
thing run in a directory routes here rather than scaffolding on its own.

## Modes

| Mode | Situation |
|---|---|
| `/init-project` | New project. Empty or nearly empty directory. |
| `/init-project adopt` | Existing project: legacy `CLAUDE.md`, no `CLAUDE.md`, or partial structure. Migrates to the hub, scaffolds only what is missing. |

Do not guess the mode from the directory alone — Step 2 detects, then confirms with Mohammed.

**The root `CLAUDE.md` is a hub.** Read `<toolkit>/guides/project-hub.md` before writing one, in
either mode. It is the single source of truth for the hub's shape and the notes discipline. The hub
points; it never accumulates findings, session history, or summaries of notes.

## Step 1: Find the Research Toolkit

The research toolkit contains templates, guides, and conventions. Find it:

1. Search for a directory containing `CLAUDE.md` with the text "Mohammed's Research Toolkit" in these locations (use Glob and Grep, search in parallel):
   - `~/.claude/skills/research-toolkit/`
   - `~/research-toolkit/`
   - `~/Research/research-toolkit/`
   - `~/Dropbox/Research/research-toolkit/`
   - Siblings of the current directory: `../research-toolkit/`
   - Parent's siblings: `../../research-toolkit/`

2. If found, store the path and move to Step 2.

3. If NOT found, ask the user:
   - Option A: "Enter the path to your research-toolkit directory"
   - Option B: "Clone from GitHub" — run `git clone https://github.com/mmogib/research-toolkit.git` to a location the user specifies, then use that path.

## Step 2: Detect Existing Content and Choose the Mode

Check the current working directory:

- Does `paper/main.tex` exist? If yes, note it — never overwrite it.
- Does `CLAUDE.md` exist? Read it and classify:
  - contains `## Active notes` → **already a hub**, no migration needed
  - contains `## Paper Key Elements`, a dated `## Current Status`, or a findings/changelog section →
    **legacy shape**, needs `adopt`
  - neither → hand-written or unknown shape, needs `adopt` with extra care
- Does `jcode/` exist and contain source files? If yes, this is a live code project.
- Is `notes/` present? `refs/`? Is this a git repository?
- Is the directory empty (or nearly empty)?

Report what you found, state which mode applies, and confirm before doing anything.

**If anything already exists, you are in `adopt` — go to the Adopt section below before Step 3.**

## Adopt Mode

For an existing project. The goal is to reach the hub without losing anything and without touching
work that is not yours.

### Safety requirements — all mandatory

1. **No-op if the root already matches the hub.** If `CLAUDE.md` contains `## Active notes`, report
   that and stop. A second or interrupted run must never re-migrate.
2. **Verbatim backup before writing anything.** Copy the existing root to
   `notes/done/CLAUDE_pre_hub.md`. If that file already exists, **do not overwrite it** — write
   `CLAUDE_pre_hub_2.md` (etc.) and report both. The original verbatim copy is the only rollback for
   a project without git.
3. **Read the backup back and compare before proceeding.** Abort before writing the new hub if it
   cannot be read back identically.
4. **Never scaffold into existing code.** If `jcode/` has content, skip Group 2 (architecture),
   Group 3 (storage and problem domain), and every DFMethods follow-up. Create no `src/` or
   `scripts/` files. That folder is not yours.
5. **Never overwrite any existing file.** Only create what is missing.
6. **Propose, then write.** Show the extraction plan and the root diff and get approval first.

### Procedure

1. Inventory the old root: every heading, every content block, every linked path.
2. Map content to destinations per the migration table in `<toolkit>/guides/project-hub.md`:
   `## Paper Key Elements` → `notes/manuscript-map.md`; known issues → topic notes; session history
   and findings → the note that owns that topic, or a one-line summary if superseded; authors,
   structure, roles, rules → carried into the new hub.
3. If `notes/manuscript-map.md` already exists, **do not merge silently** — show the proposed diff
   and get approval.
4. Ask only the questions that are still open. If a host skill invoked `adopt` and already asked who
   owns the code, it passes those answers in — **do not ask twice**.
5. Write: backup → new notes → new hub. Create missing directories (`notes/`, `notes/done/`,
   `notes/litrev/` with its README, `refs/`) but nothing under `jcode/`. If `notes/litrev/` already
   exists, leave it and its notes untouched.
6. Verify and report:
   - the backup's content matches the pre-adoption root
   - `jcode/` is byte-for-byte unchanged
   - every old heading appears in the new hub or in a named note, listed explicitly
7. Tell Mohammed to start a fresh session for this project — the old `CLAUDE.md` may still be loaded
   in the current one.

A syntactically valid hub is not evidence of success. Report the mapping, not just the result.

**LaTeX template handling:**
- If `paper/main.tex` does NOT exist: create it from `templates/main.tex.template`, filling in the title from the user's answer in Step 3. Also create an empty `paper/references.bib` and an empty `paper/temp_refs_to_add.bib` (with a header comment: `% Suggested references for Mohammed to verify and import via Zotero`). Create `paper/submissions/` directory.
- If `paper/main.tex` DOES exist: the user already has preliminary notes. Do NOT touch it. Offer to copy the LaTeX template as `paper/template_reference.tex` so the user can pull preamble/boilerplate from it if needed.

## Step 3: Ask Project Questions

Ask the user the following interactively using AskUserQuestion. Ask one group at a time, not all at once:

**Group 1 — Project identity:**
- Project title (the paper title, or a working title)
- Short codename for the project directory/module (e.g., "CondGVOP", "MISTDFPM")

**Group 2 — Coding architecture:**
- Style A (Module Package) or Style B (Flat Include)?
  - Style A: Code in `module ... end`, explicit exports, `@kwdef` configs, `@testset` tests. Best for reusable libraries, multiple algorithms, namespace isolation.
  - Style B: No module wrapper, `include("src/includes.jl")`, iterator protocol, preset system, multi-solver benchmarking. Best for single-algorithm, rapid prototyping, many variants.

**Group 3 — Storage and problem domain:**
- Storage backend: SQLite (default, recommended) or CSV-only?
  - SQLite: single `experiments.db` file, content-addressable config hashing, queryable, `--export` for CSV output.
  - CSV: manual file I/O, Set-based skip logic, backup before overwrite.
- **Problem domain (binary first question)**:
  - **(a) Nonlinear System of Equations (NLE / NLSE)** — $F(x) = 0,\ x \in X$. Triggers the full NLE/DFMethods follow-up path below.
  - **(b) Something else** — vector optimization, approximation, eigenvalue problems, variational inequalities not in F(x)=0 form, anything else. Skip all NLE follow-ups; scaffold the generic project only (the user provides their own problem definitions and solver in whatever shape their domain calls for).

**Group 3 follow-ups — only if Group 3 = (a) NLE:**

- **Solver framework** for the F(x) = 0 path:
  - **DFMethods.jl only** — scaffold the DFMethods.jl-aware adapter, callbacks, sweep helpers, and `TestProblem` registry with `set_factory::Function` returning `AbstractConstraintSet`.
  - **DFMethods.jl + bring-your-own solvers (coexistence)** — same scaffolding plus the dual-field `TestProblem` (`proj::Function` auto-derived from `set_factory` via `DFMethods.project`); benchmark scripts dispatch on `solver_kind::Symbol` per palette entry.
  - **No DFMethods** — user supplies own solver and projection. Scaffold `problems_nle.jl` with the generic `proj::Function` schema; no adapter / callbacks / sweep_helpers; no DFMethods deps in `Project.toml`.
- **Application sub-flavors** (multi-select, optional) — sub-flavors of NLE that reformulate as $F(x) = 0$ with specific structure:
  - [ ] Compressed sensing (NCP reformulation, soft-thresholding) — adds `problems_cs.jl` + `s50_compressed_sensing.jl`.
  - [ ] Image restoration (GPSR / blur + noise via NCP) — adds `problems_imgrec.jl` + `s55_image_restoration.jl`.
  - [ ] Logistic regression (regularized, LIBSVM-style) — adds `problems_logreg.jl` + `s60_logistic_regression.jl`.
- **Include the 28-problem canonical benchmark library?** (default yes)
  - **Yes** (recommended) — `src/problems_nle.jl` is scaffolded with the 28 Ibrahim-2026-style monotone problems + 18 named initial-point recipes + `PROBLEM_REGISTRY` + `INITIAL_POINTS` + lookup helpers. Citations preserved in each problem's docstring. Easy starting point for nonlinear-monotone-equations research.
  - **No** — `src/problems_nle.jl` is scaffolded with the `TestProblem` struct + empty `PROBLEM_REGISTRY` + a comment block telling the user to fill in their own.

**Group 4 — Project scope (optional, can be filled later):**
- Co-authors (names and emails), or use default (Mohammed only)?
- Brief description of the core problem (one sentence) — or skip for now?

**Group 5 — Arrangement (determines which Roles block the hub gets):**
- **Who owns code and numerical experiments?**
  - **Mohammed and Claude** (default) — Claude writes scripts, Mohammed runs them.
  - **A named collaborator owns `jcode/`** — Claude never runs, writes, or edits code there;
    experiments are requested through a spec note. Ask for the collaborator's name.

`templates/CLAUDE.md.template` carries both Roles blocks. **Emit exactly one** into the project's
`CLAUDE.md` and delete the other along with its marker comments. If a collaborator owns the code, add
the matching rule: "`jcode/` belongs to [Collaborator]. Do not run it, edit it, or rely on it."

- **Is an external AI reviewer in the loop?** — ask this **only** in `adopt` mode or when the project
  is manuscript-flavored (a `paper/main.tex` exists or is being created). Do not put it in every new
  project's interview; it is one feature, not a universal question.
  - **No** (default) — skip.
  - **Yes** — a second model with read access to the project, corresponding through `channels/` with
    Mohammed relaying by hand. Ask for its name (default: Codex). Then: invoke `/channels` to
    scaffold, append the external-reviewer overlay to the Roles block, add `channels/` to the
    Structure tree, and add the freeze rule to Rules — supplying the two values `/channels` needs,
    the frozen artifact and the findings destination.

In `adopt` mode, infer the arrangement from the old root's Roles section where one exists and confirm
it rather than asking cold. An existing `channels/` directory answers the reviewer question by
itself — confirm the helper's name rather than asking whether one is in use.

## Step 4: Read Templates

Based on the chosen style and options, read the appropriate templates from the toolkit directory:

**Always read:**
- `templates/CLAUDE.md.template`
- `templates/jcode-CLAUDE.md.template`
- `templates/Project.toml.template`
- `templates/main.tex.template` (LaTeX starter)
- `templates/types_template.jl` (SolverResult, IterRecord, make_result)
- `templates/script_smoke_test.jl`

**Style A additionally:**
- `templates/module_template.jl`
- `templates/runtests.jl.template`

**Style B additionally:**
- `templates/includes_template.jl` (has JCODE_ROOT)
- `templates/deps_template.jl`
- `templates/iterator_solver_template.jl`

**If SQLite backend:**
- `templates/benchmark_db_template.jl`

**If Group 3 problem domain = (b) Something else:**
- No additional problem-domain templates. The user provides their own problem definitions inside `src/`.

**If Group 3 problem domain = (a) NLE and solver framework = No DFMethods:**
- `templates/problems_nle_template.jl` (generic `proj::Function`-based starter).

**If Group 3 problem domain = (a) NLE and solver framework ∈ {DFMethods only, DFMethods + BYO}:**
- `templates/dfmethods/adapter_template.jl` → `src/adapter.jl`
- `templates/dfmethods/callbacks_template.jl` → `src/callbacks.jl`
- `templates/dfmethods/sweep_helpers_template.jl` → `src/sweep_helpers.jl`
- `templates/dfmethods/extras_template.jl` → `src/extras.jl` (always scaffolded; pre-populated with the LSIII/LSIV/LSV/LSVI custom line searches that complete the LSI–LSVII palette + comment block for adding custom directions / inertial rules / iterate-update strategies).
- `templates/dfmethods/constraints_nle_template.jl` → `src/constraints_nle.jl`
- If canonical 28-problem library = yes: `templates/dfmethods/problems_nle_template.jl` → `src/problems_nle.jl`. Otherwise scaffold a `src/problems_nle.jl` skeleton with the `TestProblem` struct + empty `PROBLEM_REGISTRY`.
- `templates/dfmethods/script_smoke_test.jl` → `scripts/s01_smoke_test.jl`
- `templates/dfmethods/script_benchmark.jl` → `scripts/s30_benchmark.jl`
- `templates/dfmethods/script_recovery.jl` → `scripts/s40_recovery.jl`
- `templates/dfmethods/script_figures.jl` → `scripts/s70_figures_tables.jl`
- s10_oat_sensitivity.jl and s20_parameter_search.jl scaffold from the generic templates (`templates/script_oat.jl`, `templates/script_parameter_search.jl`); the user adapts them to use `solve_with_alg` (see `<toolkit>/guides/dfmethods-integration.md` § 7).

**Per selected application sub-flavor (NLE path only):**
- Compressed sensing checked: `templates/dfmethods/problems_cs_template.jl` → `src/problems_cs.jl` + (TODO: `script_compressed_sensing.jl` in a follow-up cycle).
- Image restoration checked: `templates/dfmethods/problems_imgrec_template.jl` → `src/problems_imgrec.jl` + (TODO).
- Logistic regression checked: `templates/dfmethods/problems_logreg_template.jl` → `src/problems_logreg.jl` + (TODO).

**Reading the DFMethods quick-reference (NLE + DFMethods only):**
- `skills/init-project/references/dfmethods-quickref.md` — short cheat-sheet of `DFProjection` keyword arguments + the six built-in constraint sets. Reference at scaffold time when populating `jcode/CLAUDE.md`'s DFMethods integration section.

## Step 5: Generate Project Structure

Create the following directory tree:

```
./
├── CLAUDE.md                     ← Populated from template + user answers
├── paper/
│   ├── main.tex                  ← From LaTeX template (SKIP if already exists)
│   ├── references.bib            ← Empty file (Zotero will populate)
│   ├── temp_refs_to_add.bib      ← Claude puts suggested refs here for Mohammed to verify
│   ├── imgs/                     ← Empty directory
│   └── submissions/              ← One subfolder per journal (cover letters, responses)
├── jcode/
│   ├── CLAUDE.md                 ← Populated from template + user answers
│   ├── Project.toml              ← Populated with correct module name + DB deps
│   ├── src/
│   │   ├── includes.jl           ← Style B entry point with JCODE_ROOT
│   │   ├── deps.jl               ← Centralized dependencies (incl. SQLite if chosen)
│   │   ├── types.jl              ← SolverResult, IterRecord, make_result
│   │   ├── io_utils.jl           ← TeeIO, setup_logging, teardown_logging
│   │   ├── benchmark.jl          ← DB infrastructure (if SQLite) or CSV helpers
│   │   ├── problems_nle.jl       ← (if Group 3 = NLE) nonlinear equations starter
│   │   ├── constraints_nle.jl    ← (if NLE + DFMethods) constraint constructors
│   │   ├── adapter.jl            ← (if NLE + DFMethods) NonlinearSolution → SolverResult
│   │   ├── callbacks.jl          ← (if NLE + DFMethods) ProgressUpdateCallback
│   │   ├── sweep_helpers.jl      ← (if NLE + DFMethods) WorkItem, register_palette, run_sweep
│   │   ├── extras.jl             ← (if NLE + DFMethods) custom LS / direction templates
│   │   ├── problems_cs.jl        ← (if CS sub-flavor checked) compressed sensing starter
│   │   ├── problems_imgrec.jl    ← (if ImgRec sub-flavor checked) image restoration starter
│   │   ├── problems_logreg.jl    ← (if LogReg sub-flavor checked) logistic regression starter
│   │   └── algorithm.jl          ← Style B: iterator solver template (only if Group 3 = Something else; in NLE+DFMethods, the algorithm comes from the library — extras.jl holds custom extensions instead)
│   ├── scripts/
│   │   ├── s01_smoke_test.jl     ← Smoke test with solver + hash checks
│   │   ├── s10_oat_sensitivity.jl   ← (NLE path only) OAT parameter sweep
│   │   ├── s20_parameter_search.jl  ← (NLE path only) LHS parameter search
│   │   ├── s30_benchmark.jl         ← (NLE path only) full palette × problems × dims × inits sweep
│   │   ├── s40_recovery.jl          ← (NLE path only) targeted re-run of DB failures
│   │   ├── s50_compressed_sensing.jl  ← (if CS sub-flavor checked) [TODO: follow-up cycle]
│   │   ├── s55_image_restoration.jl   ← (if ImgRec sub-flavor checked) [TODO: follow-up cycle]
│   │   ├── s60_logistic_regression.jl ← (if LogReg sub-flavor checked) [TODO: follow-up cycle]
│   │   └── s70_figures_tables.jl    ← (NLE path only) Dolan-Moré performance profiles
│   ├── test/                     ← Style A: runtests.jl; Style B: empty
│   └── results/
│       └── logs/
├── notes/
│   ├── done/
│   └── litrev/                   ← One note per reference read from its PDF, by citation key
│       └── README.md             ← From /litrev's reference file
└── refs/                         ← Reference papers (PDFs) for Claude to read
```

### File Population Rules

**CLAUDE.md** (project-level) — this is the **hub**. Read `<toolkit>/guides/project-hub.md` first.
- Fill in: project title, the one-paragraph description, authors and affiliations, structure diagram,
  toolkit path
- `## Status` — three lines, Phase / Now / Next. For a new project: Phase "Project initialized",
  Now and Next from the user's answers or left as single-line placeholders
- `## Active notes` — starts empty, with the comment explaining that settled notes are not listed
- Emit **exactly one** Roles block per Group 5; delete the other and its marker comments
- Include the standard rules; append project-specific ones
- Uncomment the DFMethods pointer only if the NLE + DFMethods path was chosen
- **Do not add** per-section status tables, contribution lists, known-issues sections, or anything
  that duplicates `paper/main.tex`. The hub points; it does not restate the paper. If the user wants
  a manuscript map, it goes in `notes/manuscript-map.md` and gets one line in `## Active notes`.

**jcode/CLAUDE.md**:
- Fill in: module name, structure (matching chosen style)
- Leave algorithm-specific sections as placeholders

**jcode/Project.toml**:
- Set `name` to the codename
- Generate a UUID via Julia or leave as placeholder comment
- Include standard dependencies (LinearAlgebra, Printf, Random, Statistics, Dates, Test)
- If SQLite: add SQLite, SHA, DBInterface, JSON3, DataFrames, CSV, ProgressMeter
- If CSV-only: add DataFrames, CSV, ProgressMeter
- Comment out optional deps (Plots, LaTeXStrings, BenchmarkProfiles, LazySets) with notes
- **If NLE + DFMethods opted in**: uncomment the DFMethods integration block at the bottom of `templates/Project.toml.template` (adds `DFMethods`, `SciMLBase`, `CommonSolve`, `LineSearch` to `[deps]` and `DFMethods = "0.3.2"` to `[compat]`). The block is shipped commented; uncomment when populating the project's Project.toml.

**jcode/src/ (NLE + DFMethods only — additional populations):**
- Copy `templates/dfmethods/adapter_template.jl` → `src/adapter.jl`
- Copy `templates/dfmethods/callbacks_template.jl` → `src/callbacks.jl`
- Copy `templates/dfmethods/sweep_helpers_template.jl` → `src/sweep_helpers.jl`
- Copy `templates/dfmethods/extras_template.jl` → `src/extras.jl`
- Copy `templates/dfmethods/constraints_nle_template.jl` → `src/constraints_nle.jl`
- If canonical 28-problem library = yes: copy `templates/dfmethods/problems_nle_template.jl` → `src/problems_nle.jl`. Otherwise generate a minimal skeleton with the `TestProblem` struct and an empty `PROBLEM_REGISTRY` + comment block.
- Per sub-flavor checked: copy the corresponding `templates/dfmethods/problems_<sub>_template.jl` → `src/problems_<sub>.jl`.
- In Style B, uncomment the DFMethods integration block at the bottom of `templates/includes_template.jl` (constraints_nle → problems_nle → adapter → callbacks → extras → sweep_helpers, in that dependency order). Uncomment the same in `templates/deps_template.jl` (adds the four `using` statements).
- In Style A, the `{ModuleName}.jl` file includes the same DFMethods src files in the same dependency order, plus re-exports `solve_with_alg`, `ProgressUpdateCallback`, `WorkItem`, `register_palette`, `run_sweep`.

**jcode/scripts/ (NLE path — full s01–s70 set scaffolded at init time):**
- Copy `templates/dfmethods/script_smoke_test.jl` → `scripts/s01_smoke_test.jl` (NLE + DFMethods variant; otherwise use `templates/script_smoke_test.jl`).
- Copy `templates/script_oat.jl` → `scripts/s10_oat_sensitivity.jl` (generic template; the user adapts to call `solve_with_alg` if DFMethods).
- Copy `templates/script_parameter_search.jl` → `scripts/s20_parameter_search.jl`.
- Copy `templates/dfmethods/script_benchmark.jl` → `scripts/s30_benchmark.jl` (NLE + DFMethods variant; otherwise use `templates/script_benchmark.jl`).
- If NLE + DFMethods: copy `templates/dfmethods/script_recovery.jl` → `scripts/s40_recovery.jl`.
- Per sub-flavor checked: scaffold `s50_compressed_sensing.jl` / `s55_image_restoration.jl` / `s60_logistic_regression.jl` from the corresponding template (TODO: follow-up cycle — these templates are not yet shipped; leave a placeholder file with a comment block for now).
- Copy `templates/dfmethods/script_figures.jl` → `scripts/s70_figures_tables.jl` (NLE + DFMethods variant; otherwise use `templates/script_figures_tables.jl`).

**jcode/CLAUDE.md (NLE + DFMethods only — additional content):**
- Uncomment the DFMethods integration section at the bottom of `templates/jcode-CLAUDE.md.template` and populate with the project-specific palette names, problem count, and the user's notes.
- Reference `<toolkit>/guides/dfmethods-integration.md` as the single source of truth.

**jcode/src/** (both styles — always created):
- `types.jl` — from `templates/types_template.jl` (SolverResult, IterRecord, make_result)
- `io_utils.jl` — TeeIO implementation (from infrastructure-patterns.md)
- Domain problem files — from selected templates (e.g., `problems_nle_template.jl`)

**jcode/src/** (Style A additionally):
- `{ModuleName}.jl` — module file with includes and exports (from template)
  - Include types.jl, io_utils.jl, benchmark.jl, domain files
  - Export SolverResult, make_result, setup_logging, teardown_logging, TeeIO, open_db, make_config_hash, etc.

**jcode/src/** (Style B additionally):
- `includes.jl` — from `templates/includes_template.jl` (with JCODE_ROOT, correct include order)
  - Uncomment the domain-specific includes matching the user's checklist
- `deps.jl` — from `templates/deps_template.jl`
  - If CSV-only: comment out SQLite, SHA, DBInterface, JSON3
- `algorithm.jl` — iterator solver template (with TODOs marked)

**jcode/src/benchmark.jl** (storage-dependent):
- If SQLite: from `templates/benchmark_db_template.jl`
- If CSV-only: create minimal file with CSV helpers (header writing, append, Set-based skip, backup)

**notes/litrev/**:
- Created for every project, with `README.md` copied from
  `<toolkit>/skills/litrev/references/litrev-notes.md` (the README block), substituting `refs/` as
  the PDF root.
- This is the cite-with-confidence record: one note per reference actually read from its PDF, named
  by citation key. Scaffolded at init so the rule is in place before the first citation rather than
  retrofitted after a wrong characterization ships.
- Add one line to `## Active notes` in the hub:
  `` - `notes/litrev/` — one note per reference read from its PDF, by citation key ``
- The detailed procedure lives in `/litrev`. The hub's Rule 4 states the always-on constraint; do not
  move it into the skill, because a session that never invokes `/litrev` still must not fabricate
  references.

**refs/**:
- Empty directory. Mohammed downloads reference papers (PDFs) here when Claude needs to consult them.
- Workflow: Claude asks "Can you download [paper] into refs/?", Mohammed downloads it, Claude reads it with the Read tool.
- Typical uses: verifying a cited formula, checking a proof technique, understanding a referenced algorithm.

**jcode/scripts/s01_smoke_test.jl**:
- From `templates/script_smoke_test.jl`
- Adapt load pattern to chosen style (Style A: `using`, Style B: `include`)
- Wrapped in `main()`, with TeeIO logging
- Includes Part 1 (solver convergence) and Part 2 (config hash uniqueness)
- Solver list left empty with comment for user to fill in

**jcode/test/runtests.jl** (Style A only):
- From template, with module name filled in

## Step 6: Summary

### New project

- List all files created (with full paths)
- List any files skipped (because they already existed)
- Next steps:
  1. Run `julia --project=jcode/ -e 'import Pkg; Pkg.instantiate()'` to install dependencies
  2. Fill in the one-paragraph description and the three Status lines in `CLAUDE.md`
  3. Define test problems in the appropriate `problems_*.jl` file
  4. Implement the algorithm in `jcode/src/algorithm.jl`
  5. Add your solver to the `solvers` list in `s01_smoke_test.jl`
  6. Run the smoke test to verify basic functionality
  7. Use `/jcode-script` to create additional scripts (OAT, LHS, benchmark, figures)

### Adopt

Different summary — most of the above does not apply, and claiming it does would be wrong.

- **Backup**: path written, and confirmation it matches the pre-adoption root
- **Migration map**: every heading from the old root and where its content went. Anything dropped is
  named explicitly, with why
- **Created**: new notes and directories
- **Untouched**: `jcode/` (with the hash comparison result), `paper/`, and every pre-existing file
- **Next steps**:
  1. Review `notes/manuscript-map.md` and the other extracted notes — they were derived from the old
     root and may need editing
  2. Fill in the three Status lines
  3. Confirm `## Active notes` lists every note that is genuinely open
  4. **Start a fresh session for this project** — the old `CLAUDE.md` may still be loaded in this one
  5. Once satisfied, `notes/done/CLAUDE_pre_hub.md` can be deleted; until then it is the rollback

## Important Rules
- NEVER overwrite existing files. If a file exists, skip it and report that you skipped it.
- NEVER create `paper/main.tex` if it already exists — the user's preliminary notes are there.
- In `adopt`, the root `CLAUDE.md` is the **only** file that may be replaced, and only after a
  verified verbatim backup. Everything else is create-if-missing.
- NEVER write anything under `jcode/` in `adopt` mode when that folder already has content.
- The hub never carries findings, session history, or per-section status. If you are tempted to add
  one, it belongs in a note. See `<toolkit>/guides/project-hub.md`.
- Use the Write tool for new files. Use Edit only for existing files (which should not happen in a fresh project).
- All generated files should have real content, not just "TODO" — fill in as much as possible from the user's answers. Use placeholders only for information you genuinely don't have yet.
- The generated CLAUDE.md files should be immediately useful to Claude in future sessions.
