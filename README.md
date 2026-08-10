# Mohammed's Research Toolkit

A portable, topic-independent suite of guides, templates, skills, and conventions for computational mathematics research projects.

## Purpose

This toolkit captures Mohammed's exact research workflow, Julia coding style, and engineering practices so that Claude can instantly understand expectations at the start of any new project. It saves time by eliminating the need to re-explain conventions, coding patterns, and quality standards.

## Setup

### One-time setup (per machine)

**Step 1**: Clone the toolkit into Claude Code's skills directory:
```bash
git clone https://github.com/mmogib/research-toolkit.git ~/.claude/skills/research-toolkit
```

**Step 2**: Create directory symlinks so Claude Code discovers each skill.
Claude Code looks for `SKILL.md` at `~/.claude/skills/*/SKILL.md` (one level deep), so each skill needs a symlink at the root of `~/.claude/skills/`.

**Linux / macOS** (terminal):
```bash
cd ~/.claude/skills
for skill in research-toolkit/skills/*/; do
    ln -sf "$skill" "$(basename "$skill")"
done
```

**Windows** (open **cmd.exe as Administrator** — not Git Bash, not PowerShell):
```cmd
cd %USERPROFILE%\.claude\skills
mklink /D ai-slop research-toolkit\skills\ai-slop
mklink /D init-project research-toolkit\skills\init-project
mklink /D jcode-script research-toolkit\skills\jcode-script
mklink /D join-revision research-toolkit\skills\join-revision
mklink /D litrev research-toolkit\skills\litrev
mklink /D math-research-writer research-toolkit\skills\math-research-writer
mklink /D optimization-research-workflow research-toolkit\skills\optimization-research-workflow
mklink /D prepare-submission research-toolkit\skills\prepare-submission
mklink /D review-paper research-toolkit\skills\review-paper
mklink /D suggest-journals research-toolkit\skills\suggest-journals
mklink /D title-abstract research-toolkit\skills\title-abstract
```

> **Note on Windows**: `ln -s` in Git Bash creates *copies*, not symlinks. You must use `mklink /D` from cmd.exe. This requires Administrator privileges or Developer Mode enabled (Settings → For developers → Developer Mode).
>
> If neither is available, use a directory junction instead — `mklink /J <name> research-toolkit\skills\<name>` works from an unelevated shell, and Claude Code follows it exactly as it follows a symlink. This is how `prepare-submission` was deployed.

> **Note on Claude Code updates**: As of March 2026, Claude Code discovers skills by scanning `~/.claude/skills/*/SKILL.md`. If a future version introduces a native skill installation mechanism, the symlink step may become unnecessary. Check [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for the latest setup instructions.

### Development workflow

To improve the toolkit (add guides, update skills, fix templates):

**Edit only the development clone.** The runtime copy at `~/.claude/skills/research-toolkit` is
read-only: everything installed under `~/.claude/skills/` resolves into it, so a local edit there is
invisible to the development clone and silently diverges from what is pushed.

```bash
# 1. Edit in the development clone only
cd <your-development-copy>

# 2. Stage named paths — never `git add .`, which sweeps up working notes,
#    correspondence, and local operational files
git add <paths> && git commit -m "description" && git push

# 3. Pull into the runtime copy, fast-forward only
cd ~/.claude/skills/research-toolkit
git status --porcelain=v1   # must be empty; stop if not
git pull --ff-only

# 4. Confirm the two clones agree — compare full SHAs, not branch names
git -C <your-development-copy> rev-parse HEAD
git -C ~/.claude/skills/research-toolkit rev-parse HEAD
```

Deploy in a maintenance window with Claude Code sessions closed. An already-invoked `SKILL.md` stays
in its conversation and is not reread, so a session spanning a deployment runs a mix of old and new.

### Starting a new project

Use the `/init-project` slash command, which auto-discovers the toolkit and scaffolds the full project structure. Or manually:

1. Copy `templates/CLAUDE.md.template` to your project root
2. Add the toolkit path: `See ~/.claude/skills/research-toolkit for coding style, templates, and workflow guides.`
3. Choose Style A or B and copy appropriate templates

## Structure

```
research-toolkit/
├── CLAUDE.md                              # Master guide (rules, links)
├── README.md                              # This file
├── guides/                                # Detailed reference documents
│   ├── coding-style.md                    #   Julia patterns, types, naming, errors
│   ├── script-patterns.md                 #   ARGS, --resume, CSV, TeeIO, progress
│   ├── experiment-workflow.md             #   12-phase pipeline (problems → figures)
│   ├── paper-review-checklist.md          #   13-item paper polish checklist
│   └── latex-conventions.md               #   Writing style, theorems, biblatex
├── templates/                             # Copy-paste starters
│   ├── CLAUDE.md.template                 #   Project-level CLAUDE.md
│   ├── jcode-CLAUDE.md.template           #   Implementation CLAUDE.md
│   ├── main.tex.template                  #   LaTeX manuscript starter
│   ├── Project.toml.template              #   Julia project skeleton
│   ├── module_template.jl                 #   Style A module skeleton
│   ├── includes_template.jl               #   Style B flat entry point
│   ├── deps_template.jl                   #   Style B dependencies
│   ├── iterator_solver_template.jl        #   Style B algorithm template
│   ├── script_benchmark.jl               #   Benchmark script template
│   ├── script_figure.jl                   #   Figure generation template
│   └── runtests.jl.template               #   Style A test suite
└── skills/                                # Claude Code skills (slash commands)
    ├── ai-slop/                           #   /ai-slop — multi-agent AI-slop sweep
    ├── init-project/                      #   /init-project — project scaffolding
    ├── jcode-script/                      #   /jcode-script — experiment scripts
    ├── join-revision/                     #   /join-revision — revision-phase workflow
    ├── litrev/                            #   /litrev — cite-with-confidence record
    ├── math-research-writer/              #   /math-research-writer — paper writing
    ├── optimization-research-workflow/    #   /optimization-research-workflow — 12 phases
    ├── prepare-submission/                #   /prepare-submission — journal packaging
    ├── review-paper/                      #   /review-paper — 13-item checklist
    ├── suggest-journals/                  #   /suggest-journals — journal search
    └── title-abstract/                    #   /title-abstract — titles & abstracts
```

## Two Coding Architectures

**Style A — Module Package** (e.g., VOP-LineSearch/CondGVOP):
- Code wrapped in `module ModuleName ... end`
- Scripts load via `push!(LOAD_PATH, ...); using ModuleName`
- Best for: reusable libraries, multiple algorithms, namespace isolation

**Style B — Flat Include** (e.g., MISTDFPM, TwoGenDFM):
- No module wrapper; `src/includes.jl` is the single entry point
- Scripts load via `include("src/includes.jl")`
- Best for: rapid prototyping, single-algorithm, many variants

See `guides/coding-style.md` for full comparison and patterns.

## Skills

| Slash Command | Description |
|---|---|
| `/ai-slop` | Multi-agent AI-slop and revision-language sweep (deep style pass for revision cycles) |
| `/init-project` | Interactive scaffolding for new projects. **DFMethods.jl-aware** for NLE projects (opt-in). |
| `/jcode-script` | Experiment script generator (ARGS, CSV, resume, TeeIO). **DFMethods.jl-aware** when `adapter.jl` is detected. |
| `/join-revision` | Revision-phase workflow for a finished manuscript: working system + eight-step review, no code run |
| `/litrev` | Cite-with-confidence record: one note per reference read from its PDF; audits every characterization and parameter attribution against the source |
| `/math-research-writer` | Theorem/proof structure, LaTeX, notation |
| `/optimization-research-workflow` | 12-phase research pipeline. DFMethods.jl touchpoints in all 12 phases (only for projects that opted in). |
| `/prepare-submission` | Package a finished manuscript for one journal, one cycle: flattened `source_files/`, template transformation, trimmed `.bib`, cover letter |
| `/review-paper` | 13-item paper polish checklist |
| `/suggest-journals` | Find Q1–Q2 journals for publication |
| `/title-abstract` | Academic titles and abstracts |

## DFMethods.jl integration

For research projects in the **Nonlinear System of Equations (NLE / NLSE)** family, the toolkit can scaffold an opt-in integration with [DFMethods.jl](https://github.com/mmogib/DFMethods.jl) — a registered Julia package providing a configurable derivative-free projection framework for $F(x) = 0,\ x \in X$.

When `/init-project` Q1 (problem domain) = NLE, follow-up questions wire in:

- The **adapter** at `jcode/src/adapter.jl` (NonlinearSolution → SolverResult bridge)
- A **live-progress callback** at `jcode/src/callbacks.jl` (ProgressUpdateCallback)
- **Sweep helpers** at `jcode/src/sweep_helpers.jl` (palette, WorkItem, run_sweep with threaded mode)
- The **constraint constructors** at `jcode/src/constraints_nle.jl`
- The **28-problem canonical benchmark library** at `jcode/src/problems_nle.jl` (default yes; can be declined to scaffold a blank skeleton)
- **Custom extension skeleton** at `jcode/src/extras.jl` (pre-populated with 4 custom line searches that complete the LSI–LSVII palette + comment block for custom directions / inertial rules / iterate-update strategies)
- Application sub-flavor scaffolds: `problems_cs.jl` / `problems_imgrec.jl` / `problems_logreg.jl` if selected.
- Full s01 / s10 / s20 / s30 / s40 / s70 scripts in `jcode/scripts/`.

`/jcode-script` then auto-detects the integration (presence of `jcode/src/adapter.jl`) and generates DFMethods-aware variants of s30 / s40 / s70 by default.

Single source of truth for the integration patterns: [`guides/dfmethods-integration.md`](guides/dfmethods-integration.md). The integration is **opt-in** — projects outside the NLE family or projects that decline DFMethods at the solver-framework question are completely unaffected.

## Portability

One GitHub repo. Clone once per machine. Skills are discovered via symlinks. Guides, templates, and skills all live together — no separate repos, no drift.
