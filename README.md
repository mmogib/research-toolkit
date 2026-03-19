# Mohammed's Research Toolkit

A portable, topic-independent suite of guides, templates, skills, and conventions for computational mathematics research projects.

## Purpose

This toolkit captures Mohammed's exact research workflow, Julia coding style, and engineering practices so that Claude can instantly understand expectations at the start of any new project. It saves time by eliminating the need to re-explain conventions, coding patterns, and quality standards.

## Setup

### One-time setup (per machine)

```bash
# 1. Clone the toolkit into Claude Code's skills directory
git clone https://github.com/mmogib/research-toolkit.git ~/.claude/skills/research-toolkit

# 2. Create symlinks so Claude Code discovers each skill
#    (Claude looks for SKILL.md at ~/.claude/skills/*/SKILL.md)

# --- Linux / macOS ---
cd ~/.claude/skills
for skill in research-toolkit/skills/*/; do
    ln -sf "$skill" "$(basename $skill)"
done

# --- Windows (run as Administrator) ---
cd %USERPROFILE%\.claude\skills
for /D %s in (research-toolkit\skills\*) do mklink /D "%~ns" "research-toolkit\skills\%~ns"
```

### Development workflow

To improve the toolkit (add guides, update skills, fix templates):

```bash
# Edit anywhere (e.g., Dropbox clone, or the ~/.claude copy itself)
# Then push:
cd <your-development-copy>
git add . && git commit -m "description" && git push

# Pull into the runtime copy:
cd ~/.claude/skills/research-toolkit
git pull
```

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
    ├── init-project/                      #   /init-project — project scaffolding
    ├── jcode-script/                      #   /jcode-script — experiment scripts
    ├── math-research-writer/              #   /math-research-writer — paper writing
    ├── optimization-research-workflow/    #   /optimization-research-workflow — 12 phases
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
| `/init-project` | Interactive scaffolding for new projects |
| `/jcode-script` | Experiment script generator (ARGS, CSV, resume, TeeIO) |
| `/math-research-writer` | Theorem/proof structure, LaTeX, notation |
| `/optimization-research-workflow` | 12-phase research pipeline |
| `/review-paper` | 13-item paper polish checklist |
| `/suggest-journals` | Find Q1–Q2 journals for publication |
| `/title-abstract` | Academic titles and abstracts |

## Portability

One GitHub repo. Clone once per machine. Skills are discovered via symlinks. Guides, templates, and skills all live together — no separate repos, no drift.
