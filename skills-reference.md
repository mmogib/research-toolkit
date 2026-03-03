# Skills Reference

Mohammed has seven custom skills at `~/.claude/skills/mohammed-research-skills/`. These are invoked via slash commands during Claude Code sessions.

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

### 4. `/init-project`
**When to use**: Starting a brand new research project from scratch.

**What it provides**:
- Interactive directory scaffolding (paper/, jcode/, notes/, refs/)
- CLAUDE.md files for project and implementation subdirectory
- Julia project setup with chosen architecture (Style A or B)
- Template copying from the research toolkit

### 5. `/jcode-script`
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

### 6. `/review-paper`
**When to use**: Reviewing, polishing, or doing a final pass on an academic paper before submission.

**What it provides**:
- 13-item universal review checklist (notation, proofs, assumptions, abstract, style, etc.)
- Interactive addition of project-specific review tasks
- Task distribution between Claude (automatable checks) and user (mathematical judgment)
- Automated execution of Claude-assigned items with findings reported per item
- Tracked checklist note in `notes/review_checklist_YYYYMMDD.md`

**Reference files** (1):
- `checklist-items.md` — Full universal checklist with detailed sub-items, banned words, wordy phrase replacements

### 7. `/suggest-journals`
**When to use**: Looking for suitable journals to submit a paper, or reviewing/updating a previous journal shortlist.

**What it provides**:
- Interactive preference gathering (quartile, indexing, publisher exclusions, access model, response time)
- Web search across Scimago SJR, publisher journal finders, and community sources (Reddit, ResearchGate, SciRev)
- Filtering by ISI/Scopus indexing, quartile, publisher, and access model
- Ranked output with scope fit, impact factor, SJR, and reported response times
- Formatted note saved to `notes/journal_suggestions_YYYYMMDD.md`

**Reference files** (2):
- `references/search-strategy.md` — Web search patterns, URL structures, cross-checking methods, red flags
- `references/output-template.md` — Markdown template for the output note

## How Skills Relate to the Toolkit

The skills focus on **workflow, writing, and review**. This toolkit adds:
- **Coding style** (`guides/coding-style.md`) — Julia SE patterns not covered by skills
- **Script patterns** (`guides/script-patterns.md`) — Detailed code patterns with examples
- **Review checklist** (`guides/paper-review-checklist.md`) — Standalone reference version of the review checklist (skill `/review-paper` builds on this)
- **LaTeX conventions** (`guides/latex-conventions.md`) — Specific notation and environment choices
- **Templates** — Copy-paste starters for new projects

Together, skills + toolkit cover the full research lifecycle:
```
Skills (workflow)     → How to organize and plan
Skills (writing)      → How to write math and abstracts
Skills (review)       → How to polish before submission
Skills (journals)     → Where to submit
Toolkit (coding)      → How to implement experiments
Toolkit (templates)   → How to bootstrap a new project
```
