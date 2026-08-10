# CLAUDE.md files in an optimization project

Two files, two different jobs. They follow different rules, and conflating them is the mistake this
document exists to prevent.

## Root `CLAUDE.md` — the hub

**See `<toolkit>/guides/project-hub.md`.** That guide is the single source of truth for the root
file's shape, the `## Active notes` index, and the flat undated notes discipline. `/init-project`
writes it; `/init-project adopt` migrates an existing one.

The short version: the hub answers *where does the project stand* and *where do I look next*, in
about one screen. It carries a one-paragraph description, three Status lines (Phase / Now / Next), the
Active notes index, structure, roles, rules, and the toolkit path.

It does **not** carry session history, completed-item logs, key findings with numbers, next-step
lists, or per-section status tables. Those rot, and a session that reads them believes things that
stopped being true. Findings go in the note that owns the experiment; the hub points at the note.

> **If you are working in a project whose root has a `## Paper Key Elements` block, a dated
> `## Current Status`, or an inline findings section, it predates this doctrine.** Run
> `/init-project adopt` rather than continuing to append to it.

---

## `jcode/CLAUDE.md` — implementation reference

A different kind of document, and **the hub discipline does not apply to it**. This one is expected to
be long, detailed, and full of tables. Do not trim it to match the root.

### Structure

```markdown
# ALGORITHM_NAME Implementation

## Overview
What algorithm, what paper, what problem it solves.

## File Structure
Directory tree with every source file and script described.

## Important Rules
### Dependencies
Where to put `using` statements.
### Running Scripts
Whether Claude should run scripts automatically.

## Usage
Code examples showing how to construct and run the algorithm.
Include presets, parameter overrides, reference algorithms.

### Presets
Table of available presets with descriptions.

## Algorithm Summary
Table mapping algorithm steps to implementation functions.

## Parameters
### Constructor
Table of all parameters: name, default value, description, constraints.
### Line Search Types / Direction Types
Tables for categorical parameters.

## Key Components
Description of each source file and its public functions.

### solve() Common Kwargs
Table of solve() parameters shared across all algorithms.

## Dependencies
Code block showing deps.jl contents.
List script-only dependencies.

## Running Scripts
Code examples for every script with ARGS dispatch.
### Script ARGS reference
Table: Script | Valid parts | Tiers/Phases.

## Connection to Paper
Where to find the algorithm, theorems, lemmas in the paper.
```

### Key principles

1. **Document every parameter.** A table with name, default, and description is essential for
   parameter search.
2. **Show usage examples.** Claude learns from examples — constructor calls, solve calls, iterator
   usage.
3. **ARGS reference table.** Quick lookup for which parts each script supports.
4. **Connection to paper.** Helps when writing results sections or checking an implementation against
   its theorem.
5. **Detail belongs here, not in the root.** This is the right home for parameter tables, retcode
   mappings, and integration specifics.

---

## Anti-patterns

Applying to either file:

1. **Status that is a log.** Appending rather than replacing. The root's Status is three lines,
   rewritten in place; anything historical belongs in a note.
2. **Findings in the root.** "MISTTDFPM: mean 8.9 vs 14.6 iterations" is valuable and belongs in the
   note that owns that experiment, with the root's Active-notes index pointing at it.
3. **Missing rules.** If you want Claude to behave a certain way, write it in Rules. Do not assume.
4. **No pointers.** Without cross-references, a session does not know where to look.
5. **Trimming `jcode/CLAUDE.md`.** The one-screen limit is a rule about the root hub. Cutting the
   parameter tables here removes the reason the file exists.
