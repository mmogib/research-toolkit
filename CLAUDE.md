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

## Existing Skills
Mohammed has three custom skills at `~/.claude/skills/mohammed-research-skills/`:
- **optimization-research-workflow** — 12-phase research workflow, script patterns, benchmark patterns, CLAUDE.md conventions
- **math-research-writer** — Theorem/proof structure, LaTeX patterns, notation consistency, convergence analysis writing
- **title-abstract** — Academic paper titles and abstracts (structure, examples, journal requirements)

See `skills-reference.md` for details on when and how to invoke each skill.

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
| Template | Style | Purpose |
|----------|-------|---------|
| `templates/CLAUDE.md.template` | Both | Project-level CLAUDE.md for a new research project |
| `templates/jcode-CLAUDE.md.template` | Both | Implementation subdirectory CLAUDE.md |
| `templates/Project.toml.template` | Both | Julia project skeleton |
| `templates/module_template.jl` | A | Module skeleton (includes, exports, type hierarchy) |
| `templates/includes_template.jl` | B | Flat entry point with dependency-ordered includes |
| `templates/deps_template.jl` | B | Centralized dependency management |
| `templates/iterator_solver_template.jl` | B | Algorithm as struct + iterator protocol + presets |
| `templates/script_benchmark.jl` | Both | Benchmark/experiment script with ARGS, CSV, resume, TeeIO |
| `templates/script_figure.jl` | Both | Figure generation script skeleton |
| `templates/runtests.jl.template` | A | Test suite skeleton |

## Rules (Apply to All Projects)
1. **Never run Julia scripts** — Mohammed runs them locally. Only create/edit scripts. Tests may be run.
2. **Never compile LaTeX** — Mohammed compiles locally.
3. **Never use Python scripts** — Use the Edit tool for all file modifications.
4. **Never add bib entries directly** — Mohammed adds via Zotero.
5. **Always ask questions if not 100% sure** about the approach.
6. **When presenting a plan**, always offer to save it as a note.
7. **Minimize API round trips** — batch parallel reads, prefer Edit over Write for existing files.
8. **Backup CSV data** before modifying (copy to `*_backup_YYYYMMDD.csv`).
9. **Always include --resume** when suggesting multistart/long-running commands.
10. **Avoid AI slop** — no "robust", "crucial", "comprehensive", "streamline", "leverage" in writing.
11. **No named-paragraphs or excessive bold** in LaTeX writing.
12. **Notes workflow** — plans and session findings go to `notes/`. Move completed notes to `notes/done/`.
13. **Keep CLAUDE.md current** — update after significant sessions.
