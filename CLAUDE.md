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
3. Verify symlinks still resolve: `ls -la ~/.claude/skills/mohammed-research-skills/` should point to this repo's `skills/` directory.

**Quick check:** `cd <deployed-path> && git status` — if behind, `git pull`.

## Skills (Slash Commands)
Seven custom skills in `skills/` (discovered by Claude Code via symlinks from `~/.claude/skills/`):
- `/optimization-research-workflow` — 12-phase research workflow, script patterns, benchmark patterns
- `/math-research-writer` — Theorem/proof structure, LaTeX patterns, notation consistency
- `/title-abstract` — Academic paper titles and abstracts (structure, examples, journal requirements)
- `/init-project` — Interactive scaffolding for new research projects
- `/jcode-script` — Experiment script generator: type selection, SQLite/CSV backend, CLI flags, DB infrastructure
- `/review-paper` — Paper review & polish checklist: 13-item universal checklist + project-specific items
- `/suggest-journals` — Find suitable Q1–Q2 journals for publication

## Two Coding Architectures
At project start, choose one:
- **Style A — Module Package**: Code in `module ... end`, loaded via `using ModuleName`. Explicit exports, `Base.@kwdef` config structs. Best for reusable libraries, multiple algorithms, namespace isolation.
- **Style B — Flat Include**: No module wrapper, loaded via `include("src/includes.jl")`. Global namespace, central `deps.jl`, iterator protocol, preset system. Best for single-algorithm projects, rapid prototyping, many variants.

See `guides/coding-style.md` for full comparison and patterns.

## Guides (Reference Documents)
| Guide | Purpose |
|-------|---------|
| `guides/coding-style.md` | Both architectures: types, dispatch, naming, iterators, presets, error handling |
| `guides/script-patterns.md` | Experiment script structure: ARGS, --resume, CSV I/O, TeeIO, progress bars |
| `guides/experiment-workflow.md` | End-to-end experiment pipeline: planning, OAT, LHS, benchmark, ablation, figures |
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
