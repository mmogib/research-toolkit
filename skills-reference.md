# Skills Reference

Mohammed has four custom skills at `~/.claude/skills/mohammed-research-skills/`. These are invoked via slash commands during Claude Code sessions.

## Available Skills

### 1. `/optimization-research-workflow`
**When to use**: Starting a new research project, planning experiments, or setting up project infrastructure.

**What it provides**:
- 12-phase research workflow (from literature review through paper submission)
- Decision gates between phases
- Script naming and numbering conventions
- Benchmark infrastructure patterns (OAT, LHS, multi-start, ablation)
- CLAUDE.md writing guide for new projects
- Project template instantiation guide

**Reference files** (5):
- `workflow-phases.md` — Detailed 12-phase workflow
- `script-patterns.md` — 10 reusable Julia script patterns
- `benchmark-patterns.md` — Benchmarking infrastructure
- `claude-md-guide.md` — How to write effective CLAUDE.md files
- `template-usage.md` — Project template instantiation

### 2. `/math-research-writer`
**When to use**: Writing or reviewing mathematical content (theorems, proofs, definitions, convergence analysis).

**What it provides**:
- Theorem/proof writing structure
- LaTeX environment patterns
- Notation consistency guidelines
- Convergence analysis writing patterns
- How to handle assumptions, lemmas, and proof chains

### 3. `/title-abstract`
**When to use**: Drafting or polishing paper titles and abstracts.

**What it provides**:
- Title writing guidelines (length, structure, keyword placement)
- Abstract structure (problem, method, results, significance)
- Journal-specific requirements (SIAM, Springer, Elsevier, AMS)
- Real examples with analysis
- Pre-submission checklists

**Reference files** (7):
- `title-guidelines.md`, `abstract-guidelines.md`, `document-types.md`
- `journal-requirements.md`, `examples.md`, `checklists.md`, `resources.md`

### 4. `/jcode-script`
**When to use**: Creating a new experiment script (benchmark, ablation, figure, etc.) with consistent structure and patterns.

**What it provides**:
- Interactive script type selection with automatic `s{NN}_` numbering
- Feature composition (ARGS, resume, summary mode, TeeIO, CSV I/O, progress bars, etc.)
- Infrastructure setup (creates/updates `io_utils.jl`, `utils.jl` as needed)
- Dependency management (adds packages to Project.toml or deps.jl based on style)
- Works with both Style A (Module Package) and Style B (Flat Include)
- Can adapt patterns to Python or MATLAB when explicitly requested

**Reference files** (3):
- `script-patterns.md` — Composable code blocks for each feature
- `infrastructure-patterns.md` — Canonical io_utils.jl and utils.jl code
- `dependency-guide.md` — Feature → package mapping, installation instructions

## How Skills Relate to the Toolkit

The skills focus on **workflow and writing**. This toolkit adds:
- **Coding style** (`guides/coding-style.md`) — Julia SE patterns not covered by skills
- **Script patterns** (`guides/script-patterns.md`) — Detailed code patterns with examples
- **Review checklist** (`guides/paper-review-checklist.md`) — Post-writing polish workflow
- **LaTeX conventions** (`guides/latex-conventions.md`) — Specific notation and environment choices
- **Templates** — Copy-paste starters for new projects

Together, skills + toolkit cover the full research lifecycle:
```
Skills (workflow)     → How to organize and plan
Skills (writing)      → How to write math and abstracts
Toolkit (coding)      → How to implement experiments
Toolkit (review)      → How to polish before submission
Toolkit (templates)   → How to bootstrap a new project
```
