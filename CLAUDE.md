# Mohammed's Research Toolkit

## What This Is
A portable, topic-independent reference for Claude to understand Mohammed's exact research workflow, coding style, and engineering practices. Load this at the start of any new research project.

## How to Use
In any new research project, add to the project's `CLAUDE.md`:
```
## Toolkit
See `<path-to-research-toolkit>` for coding style, templates, and workflow guides.
```
Replace `<path-to-research-toolkit>` with the actual local path where this toolkit is cloned.
Claude will then have access to all guides and templates.

## Deployment
This toolkit is a git repo. Skills are discovered by Claude Code via symlinks from `~/.claude/skills/` pointing into this repo.

**After making changes** (editing templates, guides, or skills), remember to:
1. Commit and push from the development location.
2. `git pull` at the deployed location if it differs (e.g., if you develop on one machine and deploy on another, or if the Dropbox sync is not the same directory the symlinks point to).
3. Verify the installed entries still resolve. Each skill is exposed as its own entry under `~/.claude/skills/<name>` (a symlink or junction into the deployed clone's `skills/<name>/`), so check the entries themselves and read one `SKILL.md` through its exposed path:
   ```bash
   ls -la ~/.claude/skills/                              # every entry → research-toolkit/skills/<name>
   head -3 ~/.claude/skills/<any-skill>/SKILL.md         # readable through the link
   ```

**Quick check:** compare full SHAs, not branch names — `git -C <deployed-path> rev-parse HEAD` against the development clone. Deployed clone must be clean; pull with `--ff-only`.

**Never edit the deployed clone.** Everything installed resolves into it, so a local edit there diverges silently from what is pushed.

## Skills (Slash Commands)
Thirteen custom skills in `skills/` (discovered by Claude Code via symlinks from `~/.claude/skills/`):
- `/optimization-research-workflow` — 12-phase research workflow, script patterns, benchmark patterns. **DFMethods.jl-aware**: per-phase touchpoints for projects that opted into DFMethods at init time.
- `/math-research-writer` — Theorem/proof structure, LaTeX patterns, notation consistency
- `/title-abstract` — Academic paper titles and abstracts (structure, examples, journal requirements)
- `/init-project` — Scaffolding for research projects, and **sole owner of the root `CLAUDE.md` hub**. Default mode creates a new project; `adopt` mode brings an existing or legacy project onto the hub (verbatim backup, extract-then-trim migration, never touches existing `jcode/`). Emits one Roles variant per the arrangement interview. **DFMethods.jl-aware**: when the user picks NLE/NLSE as the problem domain, an opt-in question wires in the DFMethods.jl adapter, callbacks, sweep helpers, constraints / problem registry, and the 28-problem canonical benchmark library (default yes).
- `/jcode-script` — Experiment script generator: type selection, SQLite/CSV backend, CLI flags, DB infrastructure. **DFMethods.jl-aware**: detects `jcode/src/adapter.jl` to auto-select DFMethods-aware variants of s30 / s40 / s70.
- `/review-paper` — Paper review & polish checklist: 13-item universal checklist + project-specific items
- `/join-revision` — Join a fully developed manuscript in its review-and-revision phase. Sets up the working system (lean CLAUDE.md hub, flat undated notes, `notes/litrev/` cite-with-confidence records, `channels/` correspondence with an external AI reviewer, `\rev` blue markup), then drives an eight-step review ending in `/ai-slop`. No code is ever run or written — numerical experiments are audited adversarially and requested via a spec note.
- `/numerics-audit` — Adversarial audit of numerical experiments against the paper's claims: claim inventory with verdicts, whether the test problems can exercise the selling points at all, stopping-criterion comparability, evaluation accounting, timing credibility, baseline fairness, figure–table agreement, reproducibility. Four modes — `collaborator-owned`, `self-owned`, `no-runner`, `referee` — each supplying evidence lookup, findings sink, markup policy, experiment handoff, and decision owner, so nothing is hardcoded. Optional fan-out is **by lens, not by chunk**, with read-only subagents. `/ai-slop` audits the prose; this audits the numbers.
- `/channels` — Run a `channels/` correspondence with an external AI reviewer that has read access but no direct link to Claude, with Mohammed relaying by hand. Scaffolds the protocol, composes bounded numbered messages (one task, a definite done-state, no hints on adversarial checks), maintains the exchange index, and closes the loop through **separate receipt, verification, and adoption** steps — a reply landing is not a decision. The freeze rule is arrangement: the host supplies the frozen artifact and the findings destination.
- `/litrev` — Cite with confidence. Maintains `notes/litrev/` (one note per reference actually read from its PDF, keyed by citation key) and audits a manuscript against it: what is cited but unread, whether every characterization and benchmark-parameter attribution matches the source, and which essential lineage is uncited. Two modes — `audit-manuscript` and `build-from-reading`. Owns the unverified-lead request flow for `paper/temp_refs_to_add.bib`. The always-on never-fabricate rule stays in Rule 4 above, because a session that never invokes the skill still must not fabricate.
- `/suggest-journals` — Find suitable Q1–Q2 journals for publication
- `/prepare-submission` — Package a finished manuscript for one journal, one cycle. Creates `paper/submissions/[JOURNAL]/[cycle]_submission_[Month]_[Year]/` with a flattened, upload-ready `source_files/` and an empty `journal_files/` (the user's), transforms `main.tex` onto the journal template, trims the bibliography to cited keys, and scaffolds cover letter / response to reviewers / manifest on approval. `paper/main.tex` stays frozen — the derivation restructures and reformats, never changes content; content changes go upstream and are re-derived with `refresh`. Never compiles LaTeX.
- `/ai-slop` — Multi-agent AI-slop and revision-language sweep: chunked parallel agents, Tier 1/2 triage, complements `/review-paper` item 13 for revision cycles

**DFMethods.jl integration**: the toolkit ships `templates/dfmethods/` (adapter, callbacks, sweep helpers, constraint constructors, the 28-problem canonical NLE library, s01 / s30 / s40 / s70 scripts) and a dedicated single-source-of-truth guide at `guides/dfmethods-integration.md`. The integration is an **opt-in** feature gated on the NLE/NLSE problem domain — projects outside that domain are unaffected. Library: <https://github.com/mmogib/DFMethods.jl> (v0.3.2+).

## Two Coding Architectures
At project start, choose one:
- **Style A — Module Package**: Code in `module ... end`, loaded via `using ModuleName`. Explicit exports, `Base.@kwdef` config structs. Best for reusable libraries, multiple algorithms, namespace isolation.
- **Style B — Flat Include**: No module wrapper, loaded via `include("src/includes.jl")`. Global namespace, central `deps.jl`, iterator protocol, preset system. Best for single-algorithm projects, rapid prototyping, many variants.

See `guides/coding-style.md` for full comparison and patterns.

## Guides (Reference Documents)
| Guide | Purpose |
|-------|---------|
| `guides/project-hub.md` | The root `CLAUDE.md` hub: anatomy, hard limits, the Active-notes index, flat undated notes discipline, and the migration procedure for legacy projects. Single source of truth — `/init-project` writes it. |
| `guides/coding-style.md` | Both architectures: types, dispatch, naming, iterators, presets, error handling |
| `guides/script-patterns.md` | Experiment script structure: ARGS, --resume, CSV I/O, TeeIO, progress bars. Blocks 29 + 30 cover DFMethods.jl palette + run_sweep. |
| `guides/experiment-workflow.md` | End-to-end experiment pipeline: planning, OAT, LHS, benchmark, ablation, figures |
| `guides/dfmethods-integration.md` | DFMethods.jl integration patterns: adapter, callbacks, sweep helpers, constraint sets, palette + config hashing, threaded sweeps, recovery sweeps, figures, custom extensions. Reference only when a project opts into DFMethods at init time. |
| `guides/paper-review-checklist.md` | 13-item paper polish checklist (proofs, notation, style, bibliography) |
| `guides/latex-conventions.md` | Writing style, theorem environments, notation, cross-references, biblatex |

## Templates (Copy-Paste Starters)

### Project scaffolding
| Template | Style | Purpose |
|----------|-------|---------|
| `templates/main.tex.template` | Both | LaTeX starter (Palatino, biblatex, theorem envs, boilerplate) |
| `templates/CLAUDE.md.template` | Both | Project-level CLAUDE.md for a new research project |
| `templates/jcode-CLAUDE.md.template` | Both | Implementation subdirectory CLAUDE.md |
| `templates/Project.toml.template` | Both | Julia project skeleton |
| `templates/runtests.jl.template` | A | Test suite skeleton |
| `templates/spec-note.md` | Both | Experiment specification for an implementer — used by `/numerics-audit`'s `collaborator-owned` handoff |

### Architecture templates (src/ files)
| Template | Style | Purpose |
|----------|-------|---------|
| `templates/module_template.jl` | A | Module skeleton (includes, exports, type hierarchy) |
| `templates/includes_template.jl` | B | Flat entry point with JCODE_ROOT, dependency-ordered includes |
| `templates/deps_template.jl` | B | Centralized dependency management (stdlib + SQLite + DataFrames) |
| `templates/types_template.jl` | Both | SolverResult, IterRecord, make_result + solver contract docs |
| `templates/benchmark_db_template.jl` | Both | DB infrastructure: open_db, config hash, CRUD, export, summary |
| `templates/iterator_solver_template.jl` | B | Algorithm as struct + iterator protocol + presets |

### Problem domain templates (src/ files, selected per project)
| Template | Domain | Purpose |
|----------|--------|---------|
| `templates/problems_nle_template.jl` | Nonlinear equations | TestProblem struct, projections, starting points with feasibility |
| `templates/problems_cs_template.jl` | Compressed sensing | NCP reformulation, measurement model, recovery metrics |
| `templates/problems_imgrec_template.jl` | Image restoration | Blur + BSNR noise, GPSR variable splitting, PSNR metrics |

### Script templates
| Template | Purpose |
|----------|---------|
| `templates/script_smoke_test.jl` | Verify all solvers + config hash uniqueness |
| `templates/script_oat.jl` | OAT sensitivity: DB-backed, --quick, --summary, --force |
| `templates/script_parameter_search.jl` | LHS parameter search: DB-backed, --quick, --summary |
| `templates/script_benchmark.jl` | Full benchmark: SQLite, WorkItem, config hash, skip-by-default, --quick |
| `templates/script_figures_tables.jl` | Performance profiles, convergence plots, LaTeX tables from DB |
| `templates/script_figure.jl` | (Legacy) Simple figure generation skeleton |

## Notes (Development Plans & Discussions)
The `notes/` folder holds development discussions, design plans, and session findings for the toolkit itself. Completed/implemented notes are moved to `notes/done/`. These are internal development artifacts — not part of the toolkit that projects consume.

## Rules (Apply to All Projects)
1. **Never run Julia scripts** — Mohammed runs them locally. Only create/edit scripts. Tests may be run.
2. **Never compile LaTeX** — Mohammed compiles locally.
3. **Never use Python scripts** — Use the Edit tool for all file modifications.
4. **Never edit `references.bib`** — it is Zotero-managed. If new references are needed, write suggested entries to `paper/temp_refs_to_add.bib` with a comment explaining why each is needed. Mohammed verifies via Google Scholar, imports through Zotero, and updates `references.bib`. Wait for confirmation before citing new keys in the manuscript. AI-generated references are frequently hallucinated (real authors + fabricated titles/journals/DOIs) — never generate bib entries from memory.
5. **Always ask questions if not 100% sure** about the approach.
6. **When presenting a plan**, always offer to save it as a note.
7. **Minimize API round trips** — batch parallel reads, prefer Edit over Write for existing files.
8. **Backup CSV data** before modifying (copy to `*_backup_YYYYMMDD.csv`).
9. **Scripts skip completed runs by default** — use `--force` to re-run. Always remind about `--force` when suggesting re-runs.
10. **Avoid AI slop** — no "robust", "crucial", "comprehensive", "streamline", "leverage" in writing.
11. **No named-paragraphs or excessive bold** in LaTeX writing.
12. **Notes workflow** — plans and session findings go to `notes/`. Move completed notes to `notes/done/`.
13. **Keep CLAUDE.md current** — update after significant sessions.
