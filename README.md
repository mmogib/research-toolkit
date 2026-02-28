# Mohammed's Research Toolkit

A portable, topic-independent suite of guides, templates, and conventions for computational mathematics research projects.

## Purpose

This toolkit captures Mohammed's exact research workflow, Julia coding style, and engineering practices so that Claude can instantly understand expectations at the start of any new project. It saves time by eliminating the need to re-explain conventions, coding patterns, and quality standards.

## How to Use

### Starting a New Project

1. Create the project directory structure:
   ```
   new-project/
   ├── CLAUDE.md         ← Copy from templates/CLAUDE.md.template
   ├── paper/
   ├── jcode/
   │   ├── CLAUDE.md     ← Copy from templates/jcode-CLAUDE.md.template
   │   ├── src/
   │   ├── scripts/
   │   ├── test/
   │   └── results/
   ├── notes/
   │   └── done/
   └── refs/
   ```

2. In the project's `CLAUDE.md`, add:
   ```
   ## Toolkit
   See `<path-to-research-toolkit>` for coding style, templates, and workflow guides.
   ```
   Replace `<path-to-research-toolkit>` with the actual local path where this toolkit is cloned.

3. Choose a coding architecture (see below) and copy the appropriate templates.

### Two Coding Architectures

**Style A — Module Package** (e.g., VOP-LineSearch/CondGVOP):
- Code wrapped in `module ModuleName ... end`
- Scripts load via `push!(LOAD_PATH, ...); using ModuleName`
- Explicit exports control API surface
- Config via `Base.@kwdef` structs
- Best for: reusable libraries, multiple algorithms sharing types, projects where you want namespace isolation

**Style B — Flat Include** (e.g., MISTDFPM):
- No module wrapper; `src/includes.jl` is the single entry point
- Scripts load via `include("src/includes.jl")`
- All functions/types in global namespace
- Centralized `deps.jl` for dependency management
- Algorithm as struct + Julia iterator protocol
- Preset system for parameter bundles
- Best for: rapid prototyping, single-algorithm projects, evolving research code with many variants

Templates are provided for both styles.

## Contents

### Guides (Reference Documents)
| File | Description |
|------|-------------|
| `guides/coding-style.md` | Julia SE patterns for both architectures, type design, naming, error handling |
| `guides/script-patterns.md` | Experiment scripts: ARGS parsing, --resume, CSV I/O, TeeIO, progress bars |
| `guides/experiment-workflow.md` | 12-phase pipeline: problems → verification → tuning → benchmark → figures |
| `guides/paper-review-checklist.md` | 13-item paper polish checklist (proofs, notation, style, bibliography) |
| `guides/latex-conventions.md` | Writing style, theorem environments, notation, biblatex conventions |

### Templates
| File | Architecture | Description |
|------|-------------|-------------|
| `templates/main.tex.template` | Both | LaTeX starter (Palatino, biblatex, theorem envs, boilerplate) |
| `templates/CLAUDE.md.template` | Both | Project-level CLAUDE.md |
| `templates/jcode-CLAUDE.md.template` | Both | Implementation subdirectory CLAUDE.md |
| `templates/Project.toml.template` | Both | Julia project skeleton |
| `templates/module_template.jl` | Style A | Module with includes, exports, type hierarchy |
| `templates/includes_template.jl` | Style B | Flat entry point with dependency order |
| `templates/deps_template.jl` | Style B | Centralized dependency management |
| `templates/iterator_solver_template.jl` | Style B | Algorithm as struct + iterator protocol + presets |
| `templates/script_benchmark.jl` | Both | Benchmark script with ARGS, CSV, resume, TeeIO |
| `templates/script_figure.jl` | Both | Figure generation with PGFPlotsX |
| `templates/runtests.jl.template` | Style A | Test suite skeleton |

### Other Files
| File | Description |
|------|-------------|
| `CLAUDE.md` | Master guide loaded by Claude (rules, links to guides and templates) |
| `skills-reference.md` | Index of existing skills at `~/.claude/skills/mohammed-research-skills/` |

## Related Skills

Three custom skills at `~/.claude/skills/mohammed-research-skills/`:
- **optimization-research-workflow** — 12-phase research workflow, script patterns, CLAUDE.md conventions
- **math-research-writer** — Theorem/proof structure, LaTeX patterns, convergence analysis
- **title-abstract** — Academic paper titles and abstracts, journal requirements

## Portability

Clone this repo anywhere on your machine. No global configuration dependencies. Any new project references this directory in its CLAUDE.md. The `/init-project` command auto-discovers the toolkit path.
